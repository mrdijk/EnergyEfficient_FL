#!/bin/bash


# Check if an argument was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <prometheus-server-string-id>"
    exit 1
fi

# First argument is the pod name
podName="$1"

# Create or update the configmap for prometheus-server
kubectl create configmap prometheus-server --from-file=prometheus.yml="/mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/charts/core/prometheus-config.yaml" -n default --dry-run=client -o yaml | kubectl apply -f-

# Restart the promtheus-server pod (delete will automatically cretae a new one)
kubectl delete pod $podName -n default