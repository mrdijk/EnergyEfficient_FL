# Preparing monitoring
This is the monitoring functionality that will be prepared.

## Preparing Prometheus
Run the script file:
```sh
# Go to the scripts path
cd cd energy-efficiency/scripts/prepare-monitoring
# Make the script executable (probably only needs to be done once)
chmod +x prometheus.sh

# Execute the script with the charts path, such as:
./prometheus.sh /mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/charts
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
# Make the script executable (probably only needs to be done once)
chmod +x keplerAndMonitoringChart.sh

# Execute the script with the charts path, such as:
./keplerAndMonitoringChart.sh /mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/charts
```