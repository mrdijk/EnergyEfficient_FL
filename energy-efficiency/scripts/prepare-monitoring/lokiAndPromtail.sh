#!/bin/bash

# Change this to the path of the DYNAMOS repository on your disk
echo "Setting up paths..."
# Path to root of DYNAMOS project on local machine
DYNAMOS_ROOT="/mnt/c/Users/cpoet/VSC_Projs/EnergyEfficiency_DYNAMOS"
# Charts
charts_path="${DYNAMOS_ROOT}/charts"
monitoring_chart="${charts_path}/monitoring"

# Create the namespace in the Kubernetes cluster (if not exists)
kubectl create namespace monitoring

# Additional information to helm chart used: https://artifacthub.io/packages/helm/grafana/loki-stack
# It includes requirements for the loki stack, such as promtail and TODO: set up other things, such as Prometheus exporter and Grafana dashboard?

# Loki and promtail from grafana charts (with release name "loki" and "promtail")
# Grafana itself was already installed and set up using prometheus-stack
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
# Install (or upgrade) loki-stack (includes promtail)
# Use the same namespace as grafana is in: monitoring
helm upgrade -i loki grafana/loki-stack --namespace monitoring --values "$monitoring_chart/loki-values.yaml"
# Uninstall the release using helm to rollback changes: 
# helm uninstall loki --namespace monitoring