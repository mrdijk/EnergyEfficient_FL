#!/bin/bash

# Change this to the path of the DYNAMOS repository on your disk
echo "Setting up paths..."
# Path to root of DYNAMOS project on local machine
DYNAMOS_ROOT="${HOME}/EnergyEfficiency_DYNAMOS"
# Charts
charts_path="${DYNAMOS_ROOT}/charts"
kubernetes_dashboard_chart="${charts_path}/kubernetes-dashboard"

# Add Kubernetes Dashboard to the Kubernetes cluster with Helm
echo "Adding Kubernetes Dashboard to cluster..."
# Add kubernetes-dashboard repository
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
# Deploy a Helm Release named "kubernetes-dashboard" using the kubernetes-dashboard chart
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard

sleep 1

# Add the service account and cluster role binding to create admin user
kubectl apply -f "${kubernetes_dashboard_chart}/templates/dashboard-adminuser.yaml"

sleep 2

# Get the token from the user and print it
echo "Getting token for login from admin user:"
kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d
# Print empty line
echo ""

echo "Finished setting up Kubernetes Dashboard"

exit 0