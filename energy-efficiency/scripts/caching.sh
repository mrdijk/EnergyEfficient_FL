#!/bin/bash

# Change this to the path of the DYNAMOS repository on your disk
echo "Setting up paths..."
# Path to root of DYNAMOS project on local machine
DYNAMOS_ROOT="/mnt/c/Users/cpoet/VSC_Projs/EnergyEfficiency_DYNAMOS"
# Charts
charts_path="${DYNAMOS_ROOT}/charts"
caching_chart="${charts_path}/caching"

# Create the namespace in the Kubernetes cluster (if not exists)
kubectl create namespace caching

# Install or upgrade Redis using helm and bitnami (Bitnami is not added in helm repos, as it failed,
# and the documentation said to do it like this: https://github.com/bitnami/charts/tree/main/bitnami/redis)
helm upgrade -i redis oci://registry-1.docker.io/bitnamicharts/redis --namespace caching -f "$caching_chart/values.yaml"
# Uninstall the release using helm to rollback changes: helm uninstall redis --namespace caching