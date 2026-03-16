#!/usr/bin/env bash
set -euo pipefail

CHART_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

pass() { echo "  PASS: $1"; ((PASS++)); }
fail() { echo "  FAIL: $1"; ((FAIL++)); }

echo "=== CRD Helm template tests ==="
echo ""

# --- Test 1: helm lint ---
echo "[Test] helm lint"
if helm lint "$CHART_DIR" --quiet 2>/dev/null; then
  pass "chart lints successfully"
else
  fail "chart lint failed"
fi

# --- Test 2: CRD rendered by default (crds.install=true) ---
echo "[Test] CRD rendered with default values"
OUTPUT=$(helm template test-release "$CHART_DIR" 2>/dev/null)
if echo "$OUTPUT" | grep -q "kind: CustomResourceDefinition"; then
  pass "CRD is rendered with default values"
else
  fail "CRD is NOT rendered with default values"
fi

# --- Test 3: CRD name is correct ---
echo "[Test] CRD name"
if echo "$OUTPUT" | grep -q "name: dataflows.dataflow.dataflow.io"; then
  pass "CRD name is dataflows.dataflow.dataflow.io"
else
  fail "CRD name mismatch"
fi

# --- Test 4: keep annotation present by default ---
echo "[Test] helm.sh/resource-policy: keep annotation (default)"
if echo "$OUTPUT" | grep -q 'helm.sh/resource-policy.*keep'; then
  pass "keep annotation present"
else
  fail "keep annotation missing"
fi

# --- Test 5: Helm labels present ---
echo "[Test] Helm labels on CRD"
if echo "$OUTPUT" | grep -q "helm.sh/chart:"; then
  pass "helm.sh/chart label present"
else
  fail "helm.sh/chart label missing"
fi

if echo "$OUTPUT" | grep -q "app.kubernetes.io/managed-by: Helm"; then
  pass "app.kubernetes.io/managed-by label present"
else
  fail "app.kubernetes.io/managed-by label missing"
fi

# --- Test 6: CRD not rendered when crds.install=false ---
echo "[Test] CRD NOT rendered with crds.install=false"
OUTPUT_NO_CRD=$(helm template test-release "$CHART_DIR" --set crds.install=false 2>/dev/null)
if echo "$OUTPUT_NO_CRD" | grep -q "kind: CustomResourceDefinition"; then
  fail "CRD is rendered when crds.install=false"
else
  pass "CRD is NOT rendered when crds.install=false"
fi

# --- Test 7: keep annotation absent when crds.keep=false ---
echo "[Test] keep annotation absent with crds.keep=false"
OUTPUT_NO_KEEP=$(helm template test-release "$CHART_DIR" --set crds.keep=false 2>/dev/null)
if echo "$OUTPUT_NO_KEEP" | grep -q 'helm.sh/resource-policy.*keep'; then
  fail "keep annotation present when crds.keep=false"
else
  pass "keep annotation absent when crds.keep=false"
fi

# --- Test 8: CRD schema contains DataFlow spec fields ---
echo "[Test] CRD schema contains expected fields"
for field in "source:" "sink:" "transformations:" "checkpointPersistence:"; do
  if echo "$OUTPUT" | grep -q "$field"; then
    pass "CRD contains field $field"
  else
    fail "CRD missing field $field"
  fi
done

echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
[ "$FAIL" -eq 0 ] || exit 1
