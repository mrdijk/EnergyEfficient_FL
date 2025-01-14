#!/bin/bash

# Change this to the path of the DYNAMOS repository on your disk
echo "Setting up paths..."
# Path to root of DYNAMOS project on local machine
DYNAMOS_ROOT="/mnt/c/Users/cpoet/VSC_Projs/EnergyEfficiency_DYNAMOS"
# Charts
charts_path="${DYNAMOS_ROOT}/charts"
monitoring_chart="${charts_path}/monitoring"
monitoring_values="$monitoring_chart/values.yaml"

# Create the namespace in the Kubernetes cluster (if not exists)
kubectl create namespace kepler

# More information on Kepler installation: https://sustainable-computing.io/installation/kepler-helm/
# Installing Prometheus (and Grafana) can be skipped, this is already done earlier 

# Install and add Kepler
helm repo add kepler https://sustainable-computing-io.github.io/kepler-helm-chart
helm repo update
# Install Kepler
# This also creates a service monitor for the prometheus stack
# Use specific version to ensure compatability (this version has worked in previous setups)
helm upgrade -i kepler kepler/kepler \
    --namespace kepler \
    --version 0.5.12 \
    --create-namespace \
    --set serviceMonitor.enabled=true \
    --set serviceMonitor.labels.release=prometheus \

# # Finally, apply/install the monitoring helm release (will use the monitoring charts,
# which includes the deamonset, service and sesrvicemonitor for cadvisor for example)
helm upgrade -i -f "$monitoring_values" monitoring $monitoring_chart
# Uninstall the release using helm to rollback changes: helm uninstall kepler --namespace kepler