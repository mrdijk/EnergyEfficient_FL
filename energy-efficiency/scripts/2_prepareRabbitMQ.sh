
#!/bin/bash

# Check if an argument was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <corePath>"
    exit 1
fi

# First argument is the corePath (the path to core folder in DYNAMOS project)
corePath="$1"

# Prometheus will be installed in Energy Consumption steps

# Install Nginx
helm install -f "$corePath/ingress-values.yaml" nginx oci://ghcr.io/nginxinc/charts/nginx-ingress -n ingress --version 0.18.0

# Install core
helm upgrade -i -f "$coreValues" core $corePath