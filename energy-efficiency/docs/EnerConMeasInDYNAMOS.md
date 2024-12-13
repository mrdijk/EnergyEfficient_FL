# Energy Consumption Measurements in DYNAMOS

TODO: update or remove this entirely at the end when getting started documentation is done.




For the energy measurement Prometheus is used. This file shortly explains how you can run Prometheus to view the metrics.

## Configure minikube to use cgroup2 driver
TODO: this still necessary???

If you have not already done this:

See this guide for detailed instructions: https://kubernetes.io/docs/concepts/architecture/cgroups/
The cgroup v2 version is required for metrics to not end up with zeros for Kepler.

1. Delete the old minikube cluster (minikube delete).

2. 
```sh
# Run minikube with:
minikube start --driver=docker

$ minikube start --docker-opt="default-ulimit=nofile=102400:102400"
Starting local Kubernetes v1.8.0 cluster...
Starting VM...
Getting VM IP address...
Moving files into cluster...
Setting up certs...
Connecting to cluster...
Setting up kubeconfig...
Starting cluster components...
Kubectl is now configured to use the cluster.
Loading cached images from config file.

$ minikube ssh "ps axw | grep docker"
 2846 ?        Ssl    0:08 /usr/bin/dockerd -H tcp://0.0.0.0:2376 -H unix:///var/run/docker.sock --tlsverify --tlscacert /etc/docker/ca.pem --tlscert /etc/docker/server.pem --tlskey /etc/docker/server-key.pem --label provider=virtualbox --insecure-registry 10.96.0.0/12 --default-ulimit=nofile=102400:102400
 2877 ?        Ssl    0:00 docker-containerd -l unix:///var/run/docker/libcontainerd/docker-containerd.sock --metrics-interval=0 --start-timeout 2m --state-dir /var/run/docker/libcontainerd/containerd --shim docker-containerd-shim --runtime docker-runc
...
```
Then use the getting started guide and start from the beginning to configure the Kubernetes cluster.

## Prometheus to view measurements
For the energy consumption measurements the prometheus-config.yaml file has been configured appropriately.

Run the following commands to view the measurements:
```sh
# Verify ServiceMonitor Configuration
kubectl get servicemonitors -n kepler

# Run the following command to get the services in the monitoring namespace
kubectl get services -n monitoring

# Port-forward to Prometheus, using the above information, Examples:
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090
# Or (depending on output of get services): kubectl port-forward svc/prometheus-server 9090:80 -n monitoring
```

It may take a while before Kepler is running, in the first attempt it took 7 minutes:
![alt text](./assets/KeplerPodRunningMinikubeDashboard.png)

When Prometheus is running (port forwarded), you can query the kepler metrics by going to the metrics explorer:
![alt text](./assets/KeplerMetricsExplorer.png)

Then search for kepler metrics to view the Kepler metrics:
![alt text](./assets/KeplerMetrics.png)

See this guide for detailed information about Kepler metrics: https://sustainable-computing.io/design/metrics/