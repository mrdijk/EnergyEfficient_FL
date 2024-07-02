#!/bin/bash

# Check if an argument was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <chartsPath>"
    exit 1
fi

# First argument is the chartsPath (the path to core folder in DYNAMOS project)
chartsPath="$1"
monitoringPath="$chartsPath/monitoring"

# Install Prometheus and Kepler for energy consumption measurements
# Add Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
# Install prometheus
# This may take a while before the pods are running (sometimes even up to more than 20 minutes)
# Also, the path to the yaml file for the values to install prometheus
# It will install Prometheus in the default namespace (required for configmap in the charts/core directory)
helm upgrade -i prometheus prometheus-community/prometheus -f "$monitoringPath/prometheus-values.yaml"


# TODO: install prometheus stack
# Advantages like using 'ServiceMonitor' or 'PodMonitor' to monitor the services and pods automatically 
# (no need to manually add the services to be monitored in scrape configs for example)
# TODO: apply the cadvisor.yaml file to create the daemonset, service and servicemonitor


# Add Kepler
helm repo add kepler https://sustainable-computing-io.github.io/kepler-helm-chart
helm repo update
# Install Kepler 
# (if you get this error: 'cannot re-use a name that is still in use', the namespace already exists and you can remove it and rerun:)
helm install kepler kepler/kepler --namespace kepler --create-namespace --set serviceMonitor.enabled=true --set serviceMonitor.labels.release=prometheus 
# After this final installation you should be able to view the Kepler namespace in minikube dashboard
# See EnerConMeasInDYNAMOS.md file for how to run Prometheus and see the metrics.