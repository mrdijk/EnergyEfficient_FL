
#!/bin/bash

# Check if an argument was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <corePath>"
    exit 1
fi

# First argument is the corePath (the path to core folder in DYNAMOS project)
corePath="$1"

# Create the namespace in the Kubernetes cluster (if not exists)
kubectl create namespace core &&
kubectl create namespace orchestrator &&
kubectl create namespace uva && 
kubectl create namespace vu && 
kubectl create namespace surf && 
kubectl create namespace ingress

# Initialize coreValues
coreValues="$corePath/values.yaml"
# Upgrade or install core helm release
helm upgrade -i -f "$coreValues" core $corePath

# Uninstall core helm release (it will fail anyway)
helm uninstall core

# Create password for a rabbit user (enerate a random 12-character password)
pw=$(openssl rand -base64 12)

# Add password to all namespaces
kubectl create secret generic rabbit --from-literal=password=$pw -n orchestrator
kubectl create secret generic rabbit --from-literal=password=$pw -n uva
kubectl create secret generic rabbit --from-literal=password=$pw -n vu
kubectl create secret generic rabbit --from-literal=password=$pw -n surf

# Hash password
docker run --rm rabbitmq:3-management rabbitmqctl hash_password $pw