#!/bin/bash

# Check if an argument was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <chartsPath>"
    exit 1
fi

# First argument is the chartsPath (the path to core folder in DYNAMOS project)
chartsPath="$1"
monitoringPath="$chartsPath/monitoring"

# Create the namespace in the Kubernetes cluster (if not exists)
kubectl create namespace monitoring

# Install and add Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Create the additional scrape configs for prometheus as a Kubernetes secret
kubectl create secret generic additional-scrape-configs --from-file="$monitoringPath/additional-scrape-configs.yaml" -n monitoring
# The helm upgrade below will use this secret to add the 
# additional scrape configs to the prometheus configmap, because this secret is used in the prometheus-config.yaml file

# Install prometheus stack (this may take a while before the pods are running (sometimes even up to more than 15 minutes))
# Use the monitoring namcespace for prometheus (and use config file, excludes grafana for now for example, because it is not needed at the moment)
# Using upgrade ensures that helm manages it correctly, this will upgrade or install if not exists
# This names the release 'prometheus'. This is VERY IMPORTANT, because this release will be used by Kepler and others to create ServiceMonitors for example
helm upgrade -i prometheus prometheus-community/kube-prometheus-stack --namespace monitoring -f "$monitoringPath/prometheus-config.yaml"