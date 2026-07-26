# Helm Charts — DataFlow Operator

Helm chart repository for [DataFlow Operator](https://github.com/dataflow-operator/dataflow) — a Kubernetes operator for streaming data.

## Adding the repository

Charts are published at **https://dataflow-operator.github.io/helm-charts**. Add the repo:

```bash
helm repo add dataflow-operator https://dataflow-operator.github.io/helm-charts
helm repo update
```

## Installing DataFlow Operator

```bash
# Install into the default namespace (dataflow-operator)
helm install dataflow-operator dataflow-operator/dataflow-operator

# Install into a custom namespace
kubectl create namespace dataflow
helm install dataflow-operator dataflow-operator/dataflow-operator -n dataflow

# Install with custom values
helm install dataflow-operator dataflow-operator/dataflow-operator \
  --set image.tag=v1.0.7 \
  --set metrics.enabled=true
```

## Upgrading

```bash
helm repo update
helm upgrade dataflow-operator dataflow-operator/dataflow-operator -n dataflow
```

## Uninstalling

```bash
helm uninstall dataflow-operator -n dataflow
```

## Charts in this repository

| Chart | Description |
|-------|-------------|
| [dataflow-operator](charts/dataflow-operator/) | DataFlow operator and optional web GUI |

## dataflow-operator configuration

Full reference: [Helm Values (docs)](https://dataflow-operator.github.io/docs/helm-values/). Key parameters (see [values.yaml](charts/dataflow-operator/values.yaml)):

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Operator image | `ghcr.io/dataflow-operator/dataflow` |
| `image.tag` | Image tag | `latest` |
| `replicaCount` | Number of operator replicas | `1` |
| `metrics.enabled` | Enable Prometheus metrics | `true` |
| `metrics.port` | Metrics port | `9090` |
| `logLevel` | Operator log level (`debug`, `info`, `warn`, `error`) | `info` |
| `rbac.create` | Create RBAC (ServiceAccount, ClusterRole, ClusterRoleBinding). ClusterRole includes permissions for checkpoint persistence (ServiceAccount, Role, RoleBinding per DataFlow when `spec.checkpointPersistence: true`). | `true` |
| `webhook.enabled` | Enable Validating Webhook for DataFlow CR | `false` |
| `gui.enabled` | Enable web GUI for Dataflows and logs | `false` |
| `serviceMonitor.enabled` | Create ServiceMonitor for Prometheus Operator | `false` |
| `serviceMonitor.interval` | Scrape interval | `30s` |
| `serviceMonitor.scrapeTimeout` | Scrape timeout | `10s` |
| `serviceMonitor.additionalLabels` | Labels for Prometheus `serviceMonitorSelector` (e.g. `release: kube-prometheus-stack`) | `{}` |
| `monitoring.prometheusRule.enabled` | Create PrometheusRule with DataFlow alerts | `false` |
| `monitoring.prometheusRule.additionalLabels` | Labels for Prometheus `ruleSelector` (e.g. `release: kube-prometheus-stack`) | `{}` |
| `monitoring.dashboard.enabled` | Install Grafana dashboard ConfigMap | `false` |

See [Web GUI documentation](../docs/docs/en/gui.md) for GUI capabilities, configuration, and deployment.

### Example: Prometheus metrics, alerts, and Grafana dashboard

Enable scraping and alerting with [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack) (adjust `release` label to match your Prometheus selectors):

```bash
helm upgrade --install dataflow-operator dataflow-operator/dataflow-operator \
  --set serviceMonitor.enabled=true \
  --set serviceMonitor.additionalLabels.release=kube-prometheus-stack \
  --set monitoring.prometheusRule.enabled=true \
  --set monitoring.prometheusRule.additionalLabels.release=kube-prometheus-stack \
  --set monitoring.dashboard.enabled=true
```

Alert rules are defined in [charts/dataflow-operator/templates/_prometheusrule.tpl](charts/dataflow-operator/templates/_prometheusrule.tpl) (9 alerts, including pipeline stall and Kafka fetch timeouts). The standalone manifest [monitoring/alerts/prometheusrule.yaml](../monitoring/alerts/prometheusrule.yaml) must stay in sync — verified by `charts/dataflow-operator/tests/prometheusrule_test.sh`.

Run chart tests:

```bash
bash charts/dataflow-operator/tests/crd_test.sh
bash charts/dataflow-operator/tests/prometheusrule_test.sh
```

### Example: install with GUI and Ingress

```bash
helm install dataflow-operator dataflow-operator/dataflow-operator \
  --set gui.enabled=true \
  --set gui.ingress.enabled=true \
  --set gui.ingress.className=nginx \
  --set gui.ingress.hosts[0].host=dataflow.example.com
```

### Example: webhook with cert-manager

```yaml
webhook:
  enabled: true
  certDir: /tmp/k8s-webhook-server/serving-certs
  secretName: dataflow-operator-webhook-cert
  # Leave caBundle empty — cert-manager will inject CA via annotation
```

## Requirements

- Kubernetes 1.21+
- Helm 3+

## License and links

- [Helm charts repo](https://github.com/dataflow-operator/helm-charts) — this repository
- [Operator source](https://github.com/dataflow-operator/dataflow)
- Maintainer: Ilya Ponomarev (ilyario)
