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
  --set image.tag=v0.1.1 \
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

Key parameters (see [values.yaml](charts/dataflow-operator/values.yaml)):

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Operator image | `ghcr.io/dataflow-operator/dataflow` |
| `image.tag` | Image tag | `latest` |
| `replicaCount` | Number of operator replicas | `1` |
| `metrics.enabled` | Enable Prometheus metrics | `true` |
| `metrics.port` | Metrics port | `9090` |
| `logLevel` | Operator log level (`debug`, `info`, `warn`, `error`) | `info` |
| `rbac.create` | Create RBAC (ServiceAccount, ClusterRole, ClusterRoleBinding) | `true` |
| `webhook.enabled` | Enable Validating Webhook for DataFlow CR | `false` |
| `gui.enabled` | Enable web GUI for Dataflows and logs | `false` |
| `serviceMonitor.enabled` | Create ServiceMonitor for Prometheus Operator | `false` |

### Example: install with GUI and Ingress

```yaml
# custom-values.yaml
gui:
  enabled: true
  ingress:
    enabled: true
    className: nginx
    hosts:
      - host: dataflow.example.com
        paths:
          - path: /
            pathType: Prefix
```

```bash
helm install dataflow-operator dataflow-operator/dataflow-operator -f custom-values.yaml
```
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
