# Getting Started with DYNAMOS

It is recommended for the energy efficiency project to use the VSC powershell for these commands! You can print variables in powershell by running this command:
```sh
$<variableName>
# e.g. $corePath
```

## Table of Contents
- [Prerequisites](./1_Prerequisites.md)
- [Preparing Kubernetes Cluster](./2_PreparingKubernetesCluster.md)
- [Preparing RabbitMQ](./3_PreparingRabbitMQ.md)
- [Deploying Other Components](./4_DeployingOtherComponents.md)
- [Building DYNAMOS Components](./5_BuildingDYNAMOSComponents.md)

# TODO: stranded at final step: cd go/make agent (the part of making the services)


# After completing getting started steps
These tutorials can be used after the getting started steps have been followed.

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

Production environment. Run these commands individually::
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