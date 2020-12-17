# Prometheus monitoring


```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install prometheus  prometheus-community/kube-prometheus-stack  --set kube-state-metrics.image.repository=keddiezane/kube-state-metrics
```
