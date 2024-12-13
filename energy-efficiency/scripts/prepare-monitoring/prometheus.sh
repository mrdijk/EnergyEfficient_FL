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