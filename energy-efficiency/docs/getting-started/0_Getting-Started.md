# Getting Started with DYNAMOS

It is recommended to use WSL (Linux OS). Install WSL and open the terminal, for example in VSC, by running:
```sh
wsl

# Extra info: you can print variables in wsl with:
echo $<variableName>
```

You can run the steps explained in the different files (running the scripts). Or you can run the commands from the scripts individually (e.g. when you already completed some of the steps of the script to avoid problems).

## Table of Contents
- [Prerequisites](./1_Prerequisites.md)
- [Preparing Kubernetes Cluster](./2_PreparingKubernetesCluster.md)
- [Preparing RabbitMQ](./3_PreparingRabbitMQ.md)
- [Deploying Other Components](./4_DeployingOtherComponents.md)
- [Building DYNAMOS Components](./5_BuildingDYNAMOSComponents.md)


# After completing getting started steps
These tutorials can be used after the getting started steps have been followed.

# You can access the minikube VM using SSH:
```sh
# Make sure minikube is running (minikube start). In this project we use Docker for the containers/VMs

# Open the SSH in minikube to access the minikube VM
minikube ssh
```

## Accessing Prometheus web UI
```sh
kubectl port-forward deploy/prometheus-server 9090:9090
```
After running this command you can access it via:
http://localhost:9090/

## Accessing Kubernetes Dashboard
Local environment (this is the one currently used):
```sh
minikube dashboard
```
It may take a while for it to start up (it will automatically open a webbrowser tab for you).

Production environments. Run these commands individually::
```sh
# Add kubernetes-dashboard repository
helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
helm repo update
# Deploy a Helm Release named "kubernetes-dashboard" using the kubernetes-dashboard chart
helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard

# Enable access to the Kubernetes dashboard
kubectl proxy
# Will be available at: http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```