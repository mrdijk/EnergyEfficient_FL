
#!/bin/bash

# Check if an argument was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <corePath>"
    exit 1
fi

# First argument is the corePath (the path to core folder in DYNAMOS project)
corePath="$1"
# Initialize coreValues
coreValues="$corePath/values.yaml"

# Install Prometheus and Kepler for energy consumption measurements
# Add Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
# Install prometheus stack (required for Kepler). 
# This may take a while, since prometheus-stack contains various tools (sometimes even up to 10 minutes)
# Also, the path to the prometheus-values.yaml file is provided to add extra configurations
# (if you get this error: 'cannot re-use a name that is still in use', the namespace already exists and you can remove it and rerun:)
helm install prometheus prometheus-community/kube-prometheus-stack -f "$corePath/prometheus-values.yaml"

# Add Kepler
helm repo add kepler https://sustainable-computing-io.github.io/kepler-helm-chart
helm repo update
helm search repo kepler
# Install Kepler 
# (if you get this error: 'cannot re-use a name that is still in use', the namespace already exists and you can remove it and rerun:)
helm install kepler kepler/kepler --namespace kepler --create-namespace --set serviceMonitor.enabled=true --set serviceMonitor.labels.release=prometheus 
# After this final installation you should be able to view the Kepler namespace in minikube dashboard
# See EnerConMeasInDYNAMOS.md file for how to run Prometheus and see the metrics.

# Install Nginx
helm install -f "$corePath/ingress-values.yaml" nginx oci://ghcr.io/nginxinc/charts/nginx-ingress -n ingress --version 0.18.0

# Install core
helm upgrade -i -f "$coreValues" core $corePath