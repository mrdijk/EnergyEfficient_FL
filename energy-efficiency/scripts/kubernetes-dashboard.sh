#!/bin/bash

# Change this to the path of the DYNAMOS repository on your disk
echo "Setting up paths..."
# Path to root of DYNAMOS project on local machine
DYNAMOS_ROOT="/mnt/c/Users/cpoet/VSC_Projs/EnergyEfficiency_DYNAMOS"
# Charts
charts_path="${DYNAMOS_ROOT}/charts"
kubernetes_dashboard_chart="${charts_path}/kubernetes-dashboard"

# Create the temporary pod
kubectl apply -f temp-pod.yaml

echo "Finished setting up Kubernetes Dashboard"

exit 0