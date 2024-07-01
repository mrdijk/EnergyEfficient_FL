#!/bin/bash

# Get all namespaces
namespaces=$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}')

# Loop through each namespace
for ns in $namespaces; do
  echo "Namespace: $ns"
  echo "---------------------------------"
  
  # Get all pods in the current namespace
  pods=$(kubectl get pods -n $ns -o jsonpath='{.items[*].metadata.name}')
  
  # Loop through each pod in the current namespace
  for pod in $pods; do
    echo "Pod: $pod"
    echo "Containers:"
    
    # Describe the pod and extract container details
    kubectl get pod $pod -n $ns -o jsonpath='{range .spec.containers[*]}{"Container Name: "}{.name}{"\nImage: "}{.image}{"\n"}{end}'    

    echo "---------------------------------"
  done
done
