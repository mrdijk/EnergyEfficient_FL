
#!/bin/bash

# Check if an argument was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <chartsPath>"
    exit 1
fi

# First argument is the chartsPath (the path to core folder in DYNAMOS project)
chartsPath="$1"
corePath="$chartsPath/core"
# Initialize coreValues
coreValues="$corePath/values.yaml"

# Install Nginx
helm install -f "$corePath/ingress-values.yaml" nginx oci://ghcr.io/nginxinc/charts/nginx-ingress -n ingress --version 0.18.0

# Install core (apply charts in core helm release)
helm upgrade -i -f "$coreValues" core $corePath

# TODO: add additional steps to prepare RabbitMQ (see mail with Jorrit, and things to get rabbitMQ pod working in Kubernetes cluster) 
# Apply the rabbit-pvc chart
helm upgrade -i -f "$chartsPath/namespaces/templates/rabbit-pvc.yaml" core $corePath
