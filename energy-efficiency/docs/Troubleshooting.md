# Infinite loading with local Kubernetes (e.g. Grafana or other Kubernetes related sources)
This can sometimes happen. You can either take a break and see if it still is loading after 15 minutes. Otherwise, you can try another solution:

The solution is to stop the Kubernetes cluster with:
```sh 
minikube stop
```

And then rerun it
```sh
minikube start
```
Possibly also restarting other things, such as forwarding Grafana.

# Using Kubernetes dashboard
Run
```sh
minikube dashboard
```
To open the dashboard. Here you can see pods running and debug it that way. For example, if you click on the three dots and select "Logs" you can view the logs of the different containers in the pod. For instance, the following error was present in one of my earlier issues:
```
ts=2024-07-01T15:35:06.232Z caller=main.go:537 level=error msg="Error loading config (--config.file=/etc/config/prometheus-config.yaml)" file=/etc/config/prometheus-config.yaml err="parsing YAML file /etc/config/prometheus-config.yaml: yaml: unmarshal errors:\n  line 5: field global already set in type config.plain"
```
Then I viewed the configMaps in the Kubernetes dashboard under Config and Storage section > Config Maps. Here I saw "prometheus-server" config map had two global sections. I then fixed my prometheus-config.yaml file and updated it:
```sh
# Create or update the config map
kubectl create configmap prometheus-server --from-file=prometheus.yml="/mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/charts/core/prometheus-config.yaml" -n default --dry-run=client -o yaml | kubectl apply -f-

# Apply Cluster role
kubectl apply -f "/mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/charts/core/prometheus-rbac.yaml"

# Then I ran (where the prometheus-server-<string> was the pod name)
kubectl delete pod prometheus-server-5787759b8c-kmt9d -n default
# Kubernetes automatically restarted this pod for me and then it worked!
```

# cadvisor metrics not container 'name' label
Make sure that you have applied the correct configmap to Prometheus and that cadvisor is running as a separate daemonset.
Firstly, run cadvisor as a separate daemonset:
```sh
# Create the daemonset using the cadvisor daemonset yaml file
kubectl apply -f "/mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/charts/core/cadvisor-daemonset.yaml"
```

Then prometheus needs to be configured appropriately:
```sh
# Create or update the configmap for prometheus-server
kubectl create configmap prometheus-server --from-file=prometheus.yml="/mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/charts/core/prometheus-config.yaml" -n default --dry-run=client -o yaml | kubectl apply -f-
 
# Restart the promtheus-server pod (delete will automatically cretae a new one)
# Replace will real pod name (prometheus-server-<string>)
kubectl delete pod prometheus-server-5787759b8c-6cmcs -n default

# Then port forward promtheus and see if it is working
kubectl port-forward svc/prometheus-server 9090:80 -n default
```
Go to the Prometheus UI and navigate to Status > Targets. Here you should see that cadvisor is in the targets:

![alt text](./assets/cadvisorInPrometheusTargetsDown.png)

At first it will say down/unhealthy, because it is still initializing. (Except if there are errors shown). In a minute (you could try refreshing the page to see it faster) it should say up and when it says you can see something like this:

![alt text](./assets/cadvisorInPrometheusTargetsUp.png)

Then you can see that the target is up and new metrics have been collected. Then you can go to /graph in the Prometheus UI to view the changes.

# Helm issues
Example:
```sh
poetoec@LAPTOP-IA1OBTR5:/mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/energy-efficiency/scripts$ helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace --wait
Error: INSTALLATION FAILED: cannot re-use a name that is still in use
```
This is related to a release or namespace that may conflict. List the repo or all releases using these commands:
```sh
# List repost
helm repo list
# List releases
helm list
# List namespaces
kubectl get namespaces

# Uninstall release
helm uninstall <releaseName>
# Delete namespaces
kubectl delete namespace <namespaceName>
```
The example error above is because the namespace already existed, after removing it and rerunning the command it worked again.

# Grafana (or other forwarded port taking too long)
```sh
E0626 17:29:45.184192   11096 portforward.go:351] error creating error stream for port 3000 -> 3000: Timeout occurred
```
This is an example of the error that can occur when the loading takes too long. What you can then do is restart the minikube cluster:
```sh
# Stop the cluster
minikube stop
# Restart the cluster
minikube start
```

If something else is taking very long, such as the port forward operation, you could try restarting wsl:
```sh
# exit wsl session (if you have a wsl session (terminal) open)
exit
# Restart wsl
wsl --shutdown

# Restart Docker Desktop to start the Docker engine
# Restart Kubernetes
minikube start

# Then retry the command
```
Something that is also important is that the services must be running. So, verify in your minikube dashboard for example that the pods and all other services are not still in status "ContainerCreating" or "Pending", because that will cause errors like:
```sh
poetoec@LAPTOP-IA1OBTR5:/mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/energy-efficiency/scripts$ kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n prometheus 9090:9090
error: timed out waiting for the condition

# Or:
poetoec@LAPTOP-IA1OBTR5:/mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/energy-efficiency/scripts$ kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n prometheus 9090:9090
error: unable to forward port because pod is not running. Current status=Pending
```

If that not works, there is probably something with the resources/services in the namespace. You can try to remove the namespace and change the configuration and recreate it. For example, I had a prometheus-config.yaml file that was not properly configured and therefore prometheus could not be used, while there where no error messages anywhere, it just took too long to access.

# Cluster role exists
```sh
poetoec@LAPTOP-IA1OBTR5:/mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/energy-efficiency/scripts$ helm install prometheus prometheus-community/kube-prometheus-stack -f "/mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/charts/core/prometheus-config.yaml"
Error: INSTALLATION FAILED: Unable to continue with install: ClusterRole "prometheus-kube-state-metrics" in namespace "" exists and cannot be imported into the current release: invalid ownership metadata; annotation validation error: key "meta.helm.sh/release-namespace" must equal "default": current value is "monitoring"
```
The easiest is to remove the cluster role with for example:
```sh
kubectl delete clusterrole prometheus-kube-state-metrics
```
This is a solution that can be used for all errors similar to the above example. Alternatively, you could delete the Kubernetes cluster and recreate it if there are too many issues with all the different resources in the Kubernetes cluster:
```sh
# Delete minikube Kubernetes cluster
minikube delete
# Recreate 
minikube start
# Follow all getting started steps again to see if it is working
```

## Script file (.sh) error
Error (or similar):
```sh
./2_prepareRabbitMQ.sh: line 1: $'\r': command not found
./2_prepareRabbitMQ.sh: line 3: $'\r': command not found
./2_prepareRabbitMQ.sh: line 47: syntax error: unexpected end of file
```
This suggests that the file has Windows style line endings (CRLF) instead of Unix/Linux-style line endings (LF).

This can be fixed by using dos2unix package:
```sh
# Install first if necessary
sudo apt-get update
sudo apt-get install dos2unix

# Convert script file to LF
# e.g.: dos2unix /mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/energy-efficiency/scripts/2_prepareRabbitMQ.sh
dos2unix <pathToFile>
```