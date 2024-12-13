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


# After completing getting started steps
These tutorials can be used after the getting started steps have been followed.

TODO: here add some helpful commands, such as startup Kubernetes Dashboard, Prometheus, etc.


## Accessing Prometheus web UI
```sh
kubectl port-forward deploy/prometheus-server 9090:9090
```
After running this command you can access it via:
http://localhost:9090/

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

