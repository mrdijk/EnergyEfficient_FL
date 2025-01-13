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

# Install and add Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Install prometheus stack (this may take a while before the pods are running (sometimes even up to minutes))
# -i flag allows helm to install it if it does not exist yet, otherwise upgrade it
# Use the monitoring namcespace for prometheus (and use config file with the -f flag)
# Using upgrade ensures that helm manages it correctly, this will upgrade or install if not exists
# This names the release 'prometheus'. This is VERY IMPORTANT, because this release will be used by Kepler and others to create ServiceMonitors for example
helm upgrade -i prometheus prometheus-community/kube-prometheus-stack --namespace monitoring -f "$monitoring_chart/prometheus-config.yaml"

# Grafana setup with loki and promtail (with release name "grafana")
# Prometheus stack already includes grafana itself with a default setup (saves time to set it up yourself)
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update 
# Create namespace (if not exists)
kubectl create namespace loki
# Install loki and promtail (or upgrade)
helm upgrade -i grafana grafana/loki --namespace loki --values "$monitoring_chart/loki-values.yaml"
helm upgrade -i grafana grafana/promtail --namespace loki
# TODO: this is not further set up for loki and promtail (now includes only installation, but not further setup), 
# but this could be something in the future. However, for now I focus on priority things, such as implement energy optimizations