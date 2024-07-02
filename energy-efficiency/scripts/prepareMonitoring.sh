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
kubectl create namespace monitoring &&
kubectl create namespace kepler

# Install and add Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
# Install prometheus stack (this may take a while before the pods are running (sometimes even up to more than 15 minutes))
# Use the monitoring namcespace for prometheus (and use config file, excludes grafana for now for example, because it is not needed at the moment)
# Using upgrade ensures that helm manages it correctly, this will upgrade or install if not exists
# This names the release 'prometheus'. This is VERY IMPORTANT, because this release will be used by Kepler and others to create ServiceMonitors for example
helm upgrade -i prometheus prometheus-community/kube-prometheus-stack --namespace monitoring -f "$monitoringPath/prometheus-values.yaml"

# TODO: install prometheus stack
# Advantages like using 'ServiceMonitor' or 'PodMonitor' to monitor the services and pods automatically 
# (no need to manually add the services to be monitored in scrape configs for example)
# TODO: apply the cadvisor.yaml file to create the daemonset, service and servicemonitor

# TODO: remove rbac file if it works without having to do it here!

# Install and add Kepler
helm repo add kepler https://sustainable-computing-io.github.io/kepler-helm-chart
helm repo update
# Install Kepler
# This also creates a service monitor for the prometheus stack
helm install kepler kepler/kepler --namespace kepler --set serviceMonitor.enabled=true --set serviceMonitor.labels.release=prometheus 
# After this final installation you should be able to view the Kepler namespace in minikube dashboard
# See EnerConMeasInDYNAMOS.md file for how to run Prometheus and see the metrics.

# Finally, apply the cadvisor operations (creates daemonset, service and service monitor)
kubectl apply -f "$monitoringPath/cadvisor-daemonset.yaml"