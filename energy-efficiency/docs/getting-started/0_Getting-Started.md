# Getting Started with DYNAMOS

It is recommended to use WSL (Linux OS). Install WSL and open the terminal, for example in VSC, by running:
```sh
wsl

# Extra info: you can print variables in wsl with:
echo $<variableName>
```

You can run the steps explained in the different files (running the scripts). Or you can choose to comment out specific parts from the script and then run it again (or run commands individually). This can be useful when you already completed some of the steps of the script for example.

Keep in mind, it takes a while until all the different services are running, so you may want to take a small break in between each steps to wait until all the services are running before you go to the next step.

## Prerequisites
- [Prerequisites](./1_Prerequisites.md)


## Follow the installation guide for DYNAMOS
After installing the prerequisites, install Linkerd:
https://github.com/Jorrit05/DYNAMOS?tab=readme-ov-file#6-linkerd
This only includes these after installing:
```sh
# Install Linkerd on cluster
linkerd install --crds | kubectl apply -f -
linkerd install --set proxyInit.runAsRoot=true | kubectl apply -f -

linkerd check
# This may take some time before everything is setup, wait until the check finishes

# Install Jaeger onto the cluster for observability
linkerd jaeger install | kubectl apply -f -

# Optionally install for insight dashboard - not currently in use
# linkerd wiz install | kubectl apply -f -
```

Then configure the system: https://github.com/Jorrit05/DYNAMOS?tab=readme-ov-file#system-configuration 
In short, this encompasses setting the correct paths and running the start script from the root of DYNAMOS:
```sh
./configuration/dynamos-configuration.sh

# When getting this error: Error: INSTALLATION FAILED: cannot re-use a name that is still in use
# This is because you already installed nginx and are using the install instead of upgrade, as you can see by the previous lines: Installing NGINX...
# Fix this by uninstalling the release nginx:
helm uninstall nginx -n ingress
# Then run the command again:
./configuration/dynamos-configuration.sh

# "running scripts is disabled on this system" error:
# 1. Close VSC/ 2. Run VSC as administrator / 3. Open powershell terminal (outside wsl) / 4. Run:
Set-ExecutionPolicy RemoteSigned
# 5. Close VSC / 6. Open VSC how you normally do and rerun the script
```

Now you can load the DYNAMOS configs shell file with some env vars and helper functions. You can add this code directly in your WSL ~/.bashrc file to not have to manually load it each time in the shell, however, for this setup we chose to not do this, since this configuration changes between different use cases (e.g. UNL and Prets) and therefore is easier to load manually each time in this case.
To load the configuration file run the following:
```sh
# Go to the scripts path
cd energy-efficiency/scripts
# Make the script executable (needs to be done once)
chmod +x dynamos-configs.sh
# Load the script in the terminal
source ./dynamos-configs.sh

# Now you can run functions, such as
deploy_core
# You need to load the file in the shell each time you restart a shell or when making changing to the dynamos-configs.sh script
```
You can change this file whenever you want, such as adding or removing helpful functions. After changes you have to load it in the shell again each time. Also, for each terminal you have to load the file, so it is recommended to use one terminal to execute those functions when developing. 



## Setup Kubernetes Dashboard
To setup Kubernetes Dashboard, run the following:
```sh
# Go to the scripts path
cd energy-efficiency/scripts
# Make the script executable (needs to be done once)
chmod +x kubernetes-dashboard.sh
# Execute the script:
./kubernetes-dashboard.sh
```
Then you can access Kubernetes Dashboard and get the token from the admin user in the kubernetes-dashboard namespace like this:
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


## Setup monitoring
TODO: add here how to setup monitoring

Run the following:
```sh
# Go to the scripts path
cd energy-efficiency/scripts
# Make the script executable (needs to be done once)
chmod +x <TODO.sh>
# Execute the script:
./<TODO.sh>

# "running scripts is disabled on this system" error:
# 1. Close VSC/ 2. Run VSC as administrator / 3. Open powershell terminal (outside wsl) / 4. Run:
Set-ExecutionPolicy RemoteSigned
# 5. Close VSC / 6. Open VSC how you normally do and rerun the script
```
This might take a while, since it is installing a lot of different things, such as prometheus-stack.

## Preparing the rest
Wait for the resources above to be created. The final message of the file will be for example:
```
Release "prometheus" has been upgraded. Happy Helming!
NAME: prometheus
LAST DEPLOYED: Tue Jul  2 13:29:32 2024
NAMESPACE: monitoring
STATUS: deployed
REVISION: 2
TEST SUITE: None
NOTES:
kube-prometheus-stack has been installed. Check its status by running:
  kubectl --namespace monitoring get pods -l "release=prometheus"
```

You can see that you can use the command to view the status:
```sh
# View status of prometheus release
kubectl --namespace monitoring get pods -l "release=prometheus"

# Example output:
NAME                                                   READY   STATUS              RESTARTS   AGE
prometheus-kube-prometheus-operator-6554f4464f-tf9k8   0/1     ContainerCreating   0          97s
prometheus-kube-state-metrics-558db85bb5-f64sh         0/1     ContainerCreating   0          97s
prometheus-prometheus-node-exporter-82mwd              0/1     ContainerCreating   0          97s
# With this example output you know that you should wait, because it is still creating the containers
```
Alternatively, you could use minikube dashboard and view the monitoring namespace and wait until the pods are running. It may take a while before all the pods are running, sometimes even up to more than 10 minutes. 

After the pods are running, you can execute the next script:
```sh
# Go to the scripts path
cd cd energy-efficiency/scripts/prepare-monitoring
# Make the script executable (needs to be done once)
chmod +x keplerAndMonitoringChart.sh

# Execute the script with the charts path, such as:
./keplerAndMonitoringChart.sh /mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/charts
```

TODO: add Grafana.


# After completing getting started steps
These tutorials can be used after the getting started steps have been followed.

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



