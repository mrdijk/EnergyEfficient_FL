# Energy Consumption Measurements in DYNAMOS

# TODO: add in master thesis when Kernel is working. With above explanation and add short explanation on Kernel using the documentation as a reference!
# TODO: add documentation on how I added energy consumption measurements to DYNAMOS in Prometheus.
# TODO: probably I need to add grafana so that I can persist the metrics from Kernel in Prometheus with Grafana.

## Configure minikube to use cgroup2 driver
See this guide for detailed instructions: https://kubernetes.io/docs/concepts/architecture/cgroups/
The cgroup v2 version is required for metrics to not end up with zeros for Kepler.

1. Delete the old minikube cluster (minikube delete).

2. 
```sh
# Run minikube with:
minikube start --driver=docker
```
Then use the getting started guide and start from the beginning to configure the Kubernetes cluster.

# TODO: change to new Prometheus stack
## Prometheus to view measurements
For the energy consumption measurements the prometheus-config.yaml file has been configured appropriately, see: C:\Users\cpoet\IdeaProjects\EnergyEfficiency_DYNAMOS\charts\core\prometheus-config.yaml

Run the following commands to view the measurements:
```sh
# Verify ServiceMonitor Configuration
kubectl get servicemonitors -n kepler

# Run the following command to get the services in the monitoring namespace
kubectl get services -n monitoring

# TODO: add new startup

# Port-forward to Prometheus, using the above information, Examples:
kubectl port-forward svc/prometheus-server 9090:80 -n monitoring
# Or (depending on output of get services): kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090
```

It may take a while before Kepler is running, in the first attempt it took 7 minutes:
![alt text](./assets/KeplerPodRunningMinikubeDashboard.png)

When Prometheus is running (port forwarded), you can query the kepler metrics by going to the metrics explorer:
![alt text](./assets/KeplerMetricsExplorer.png)

Then search for kepler metrics to view the Kepler metrics:
![alt text](./assets/KeplerMetrics.png)

See this guide for detailed information about Kepler metrics: https://sustainable-computing.io/design/metrics/

# TODO: convert everything to WSL and then retest running DYNAMOS.


<!-- ## Optional: Configuring Grafana
This is only optional. Grafana requires extra steps to setup and is way slower than Prometheus, so this is only if it is ever needed, but not mandatory. Prometheus is more than good enough!
```sh
# Grafana setup
# Install Grafana
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update
helm install grafana grafana/grafana --namespace monitoring --create-namespace
# Get the Grafana password
# Retrieve the base64 encoded password
$encodedPassword = kubectl get secret --namespace monitoring grafana -o jsonpath="{.data.admin-password}"
# Decode the password
$decodedPassword = [System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($encodedPassword))
# Output the decoded password
$decodedPassword

# Ensure the POD_NAME environment variable is set correctly
$podName = kubectl get pods --namespace monitoring -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=grafana" -o jsonpath="{.items[0].metadata.name}"
$env:POD_NAME = $podName
# Output the Pod Name to verify
Write-Output $env:POD_NAME
# Port-forward to Grafana
kubectl --namespace monitoring port-forward pod/$env:POD_NAME 3000:3000
# Then access it via http://localhost:3000/ and login with decoded password and 'admin' as username. This can take a while before login.

# Add Kepler to Grafana dashboard
# Retrieve the Grafana Pod Name
$GF_POD = kubectl get pod -n monitoring -l app.kubernetes.io/name=grafana -o jsonpath="{.items[0].metadata.name}"
# Output the Pod Name to verify
Write-Output $GF_POD
# Download the kepler dashboard.json file example: https://github.com/sustainable-computing-io/kepler/blob/main/grafana-dashboards/Kepler-Exporter-PromRules.json
# Rename it to kepler_dashboard.json. Then add it in the correct place and export the path: C:\Users\cpoet\IdeaProjects\EnergyEfficiency_DYNAMOS\energy-efficiency\kepler_dashboard.json
# Create the /tmp/dashboards directory inside the Grafana pod
kubectl exec -n monitoring $GF_POD -- mkdir -p /tmp/dashboards
# Copy the kepler_dashboard.json file to the specified location in the Grafana pod
# Make sure you are in the correct directory (where kepler_dashboard.json is loacted, e.g. cd .\energy-efficiency\)
kubectl cp kepler_dashboard.json monitoring/$($GF_POD):/tmp/dashboards/kepler_dashboard.json

# Then add the dashboard to the Grafana instance: 
# 1. go to http://localhost:3000/
# 2. Navigate to Dashboards > New > Import
# 3. Import the kepler_dashboard.json file
```  -->



<!-- ## Installing scaphandre in Kubernetes cluster
```sh
# Clone the git repository in the new project
git clone https://github.com/hubblo-org/scaphandre

# Go to the scaphandre folder
cd scaphandre

# Install scaphandre in the Kubernetes cluster using helm
helm install scaphandre helm/scaphandre --namespace monitoring
# Or: move the scaphandre folder into the charts folder and then run
helm install scaphandre --namespace monitoring

# Install Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add kube-state-metrics https://kubernetes.github.io/kube-state-metrics
helm repo update
helm install prometheus prometheus-community/prometheus --set alertmanager.persistentVolume.enabled=false --set server.persistentVolume.enabled=false

# Access prometheus
kubectl port-forward deploy/prometheus-server 9090:9090

# Remove cloned scaphandre afterwards to save space (not needed anymore)
rm -rf ./scaphandre

# Verify installation
helm list
```  -->

<!-- TODO: prometheus-values.yaml file needs to be configured to add scaphandre?
C:\Users\cpoet\IdeaProjects\EnergyEfficiency_DYNAMOS\charts\core\prometheus-values.yaml
Add this?
```yaml
- job_name: 'scaphandre'
    scrape_interval: 10s
    kubernetes_sd_configs:
    - role: endpoints
      namespaces:
        names:
        - monitoring
    relabel_configs:
    - source_labels: [__meta_kubernetes_service_label_app]
      action: keep
      regex: scaphandre
``` -->