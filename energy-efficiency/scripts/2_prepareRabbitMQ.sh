
#!/bin/bash

# Check if an argument was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <corePath>"
    exit 1
fi

# First argument is the corePath (the path to core folder in DYNAMOS project)
corePath="$1"

# Install Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
# Install in monitoring namespace
helm upgrade -i -f "$corePath/prometheus-values.yaml" monitoring prometheus-community/prometheus

# Install Nginx
helm install -f "$corePath/ingress-values.yaml" nginx oci://ghcr.io/nginxinc/charts/nginx-ingress -n ingress --version 0.18.0

# Install core
helm upgrade -i -f "$coreValues" core $corePath