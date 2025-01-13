# Getting Started with DYNAMOS

It is recommended to use WSL (Linux OS). Install WSL and open the terminal, for example in VSC, by running:
```sh
wsl

# Extra info: you can print variables in wsl with:
echo $<variableName>
```

You can run the steps explained in the different files (running the scripts). Or you can choose to comment out specific parts from the script and then run it again (or run commands individually). This can be useful when you already completed some of the steps of the script for example.

Keep in mind, it takes a while until all the different services are running, so you may want to take a small break in between each steps to wait until all the services are running before you go to the next step.

## Contents
- [Prerequisites](./1_Prerequisites.md)
- [Configuring DYNAMOS](./2_ConfiguringDYNAMOS.md)
- [Setup Monitoring](./3_SetupMonitoring.md)

## Developing in DYNAMOS additional explanation
Follow the Development guide: https://github.com/Jorrit05/DYNAMOS/tree/main/docs/development_guide

Start with installing dependencies: https://github.com/Jorrit05/DYNAMOS/tree/main/docs/development_guide/Dependencies
Specifically: https://pkg.go.dev/github.com/golang/protobuf/protoc-gen-go
(do NOT use the manual protoc installation)
TODO: finish this part

## Additional logging of traces can be viewed using Jaegar
Optionally, you could view the traces after performing requests in Jaegar:
```sh
# Run Jaegar:
kubectl port-forward -n linkerd-jaeger service/jaeger 16686:16686
# Access at http://localhost:16686/
```


# After completing getting started steps
These tutorials can be used after the getting started steps have been followed.

TODO: here add some helpful commands, such as startup Kubernetes Dashboard, Prometheus, etc.


## Using DYNAMOS config helper functions
```sh
# Go to the scripts path
cd energy-efficiency/scripts
# Load the script in the terminal
source ./dynamos-configs.sh

# Now you can run functions, such as
deploy_core
# You need to load the file in the shell each time you restart a shell or when making changing to the dynamos-configs.sh script
```
You can change this file whenever you want, such as adding or removing helpful functions. After changes you have to load it in the shell again each time. Also, for each terminal you have to load the file, so it is recommended to use one terminal to execute those functions when developing. 


## Deploying services
TODO: make script for deploying services.
```sh
# Copy required files in service folder, see docs\development_guide\Building\Makefiles.md
# For Go this is the Dockerfile, go.mod, go.sum and pkg folder for example
# TODO: more steps? Go is run go mod tidy

# Build the service, such as the api-gateway go service:
./buildNPushService.sh -s api-gateway -p /go/cmd/api-gateway
# TODO: example for python
# Then verify in Docker Desktop > Images > Hub repositories > check last pushed is few seconds ago

# Then deploy services to Kubernetes:
# First uninstall, such as:
helm uninstall api-gateway
# Deploy (using DYNAMOS config helper functions):
deploy_api_gateway
# Verify in Kubernetes Dashboard that pods are running
```


## Accessing Prometheus web UI
```sh
# Port-forward Prometheus stack
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090
# Access it at http://localhost:9090/
```


## Accessing Kubernetes Dashboard
You can access Kubernetes Dashboard and get the token from the admin user in the kubernetes-dashboard namespace like this:
```sh
# Access Kubernetes Dashboard
kubectl -n kubernetes-dashboard port-forward svc/kubernetes-dashboard-kong-proxy 8443:443
# Access it at: https://localhost:8443/
# If it says something like net::ERR_CERT_AUTHORITY_INVALID, Your connection isn't private, you can select 
# Advanced > Continue to localhost (unsafe). You can do this because you know it is Kubernetes and this is save to use

# Get the token from the admin user that can be used to login in the Kubernetes Dashboard cluster
kubectl get secret admin-user -n kubernetes-dashboard -o jsonpath={".data.token"} | base64 -d
# Add the token in the login window and you should be able to access Kubernetes Dashboard
```


## Accessing Grafana UI
```sh
# Port-forward Grafana in another WSL terminal
kubectl port-forward -n monitoring service/prometheus-grafana 3000:80
# Access it at http://localhost:3000/
# Login with username admin
# Get the password:
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

