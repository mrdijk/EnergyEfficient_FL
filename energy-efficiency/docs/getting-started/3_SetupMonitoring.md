# Setup Monitoring
This guide provides explanation on how to setup monitoring in the Kubernetes environment, including energy monitoring.

## Setup Kubernetes Dashboard
Kubernetes Dashboard can be used to monitor and manage the Kubernetes environment. To setup Kubernetes Dashboard, run the following:
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
Alternatively, you could also use k9s (https://k9scli.io/), as they both are used for the same purposes. K9s is CLI based and Kubernetes Dashboard is GUI based, but you can use which one you prefer or even use both.


## Setup Energy Monitoring
Used this guides as leading installations: 
- https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
- https://sustainable-computing.io/installation/kepler-helm/

Below is extra explanation on how to do this precisely.

### Setup Prometheus Stack (includes Grafana with initial setup (e.g. Prometheus as Data source in Grafana, etc.))
Run the following:
```sh
# Go to the scripts path (in WSL like with all other scripts)
cd energy-efficiency/scripts/prepare-monitoring
# Make the script executable (needs to be done once)
chmod +x prometheusAndGrafana.sh

# Execute the script:
./prometheusAndGrafana.sh
```
This might take a while, since it is installing a lot of different things, such as prometheus-stack.

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
Alternatively, you could use Kubernetes dashboard and view the monitoring namespace and wait until the pods are running. It may take a while before all the pods are running, sometimes even up to more than 10 minutes. 



### Preparing Kepler (energy measurements)
After the pods are running, you can execute the next script:
```sh
# Go to the scripts path
cd cd energy-efficiency/scripts/prepare-monitoring
# Make the script executable (needs to be done once)
chmod +x keplerAndMonitoringChart.sh

# Execute the script:
./keplerAndMonitoringChart.sh
```

Then add Kepler Dashboard to Grafana and verify Grafana installation:
```sh
# Port-forward Grafana in another WSL terminal
kubectl port-forward -n monitoring service/prometheus-grafana 3000:80
# Access it at http://localhost:3000/
# Login with username: admin
# Get the password:
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo

# Download the kepler_dashboard.json file: https://github.com/sustainable-computing-io/kepler/blob/main/grafana-dashboards/Kepler-Exporter.json
# Then go to Dashboards > New > Import > Add the JSON file just downloaded
```
Now you should be able see the dashboard in Grafana if you go to Dashboards > search for Kepler, such as Kepler Exporter Dashboard.

If it does not load, you can delete the grafana pod and then port-forward again and see if you can login, this fixes the issue most of the times in Kubernetes.


Finally, you can verify Kepler and cAdvisor running by port-forwarding Prometheus:
```sh
# Port-forward Prometheus stack
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090
# Access it at http://localhost:9090/
```

Check the Prometheus Targets at the Prometheus instance > Status > Targets, you should see at least cAdvisor and Kepler with up status, some targets might not be up, but that is probably fine, as long as those two are up, you are good to go:
![alt text](../assets/KeplerAndcAdvisorTargetsUp_Prometheus.png)

Then you can execute a query in Prometheus to see energy metrics from Kepler to verify Kepler is running:
```sh
sum(kepler_container_joules_total) by (pod_name, container_name, container_namespace, node)

# Or:
sum(kepler_container_joules_total) by (container_name)
```
You should now see energy metrics per container. A lof of these values will be 0, but that is correct, since these do not use energy at the moment or Kepler could not measure them. However, the system_processes container should report data pretty quickly. Doing other operations in other containers, such as /sqlDataRequest can take a while before Kepler has added those values. It can take even longer than 10 minutes. Also what you could try is restarting the Kubernetes cluster (in Docker Desktop: three dots > Quit Docker Desktop > Wait for a few seconds and start Docker Desktop again > Then wait a while again and perform some operations in your software application and see if the values are now present after some time again.). It may even take longer even after the restart, but be patient, and if after 4 hours you still have nothing you can debug further, but it took 4 hours for me one time until Kepler produced energy consumed for other containers then system_processes.

You should see logs similar to this in the kepler-<string> pod:
```sh
2025-01-14T16:04:32.012Z | WARNING: failed to read int from file: open /sys/devices/system/cpu/cpu0/online: no such file or directory
2025-01-14T16:04:32.024Z | I0114 16:04:32.024529       1 exporter.go:103] Kepler running on version: v0.7.12-dirty
2025-01-14T16:04:32.024Z | I0114 16:04:32.024713       1 config.go:293] using gCgroup ID in the BPF program: true
2025-01-14T16:04:32.024Z | I0114 16:04:32.024734       1 config.go:295] kernel version: 5.15
2025-01-14T16:04:32.024Z | I0114 16:04:32.024768       1 rapl_msr_util.go:129] failed to open path /dev/cpu/0/msr: no such file or directory
2025-01-14T16:04:32.024Z | I0114 16:04:32.024796       1 power.go:78] Unable to obtain power, use estimate method
2025-01-14T16:04:32.024Z | I0114 16:04:32.024804       1 redfish.go:169] failed to get redfish credential file path
2025-01-14T16:04:32.032Z | I0114 16:04:32.031718       1 acpi.go:71] Could not find any ACPI power meter path. Is it a VM?
2025-01-14T16:04:32.032Z | I0114 16:04:32.031769       1 power.go:79] using none to obtain power
2025-01-14T16:04:32.032Z | E0114 16:04:32.031780       1 accelerator.go:154] [DUMMY] doesn't contain GPU
2025-01-14T16:04:32.032Z | E0114 16:04:32.031816       1 exporter.go:154] failed to init GPU accelerators: no devices found
2025-01-14T16:04:32.033Z | WARNING: failed to read int from file: open /sys/devices/system/cpu/cpu0/online: no such file or directory
2025-01-14T16:04:32.033Z | I0114 16:04:32.033842       1 exporter.go:84] Number of CPUs: 14
2025-01-14T16:04:32.218Z | W0114 16:04:32.218256       1 exporter.go:135] failed to attach tp/writeback/writeback_dirty_page: neither debugfs nor tracefs are mounted. Kepler will not collect page cache write events. This will affect the DRAM power model estimation on VMs.
2025-01-14T16:04:32.299Z | W0114 16:04:32.299338       1 exporter.go:299] Failed to open perf event for CPU cycles: failed to open bpf perf event on cpu 0: no such file or directory
2025-01-14T16:04:32.301Z | E0114 16:04:32.300893       1 node.go:145] grep cpuid command output failure: exit status 1
2025-01-14T16:04:32.301Z | E0114 16:04:32.301571       1 node.go:123] getCPUArch failure: open /sys/devices/cpu/caps/pmu_name: no such file or directory
2025-01-14T16:04:32.302Z | I0114 16:04:32.302000       1 watcher.go:83] Using in cluster k8s config
2025-01-14T16:04:32.403Z | I0114 16:04:32.403312       1 watcher.go:229] k8s APIserver watcher was started
2025-01-14T16:04:32.405Z | E0114 16:04:32.404930       1 node.go:145] grep cpuid command output failure: exit status 1
2025-01-14T16:04:32.406Z | E0114 16:04:32.406575       1 node.go:123] getCPUArch failure: open /sys/devices/cpu/caps/pmu_name: no such file or directory
2025-01-14T16:04:32.406Z | I0114 16:04:32.406661       1 process_energy.go:129] Using the Ratio Power Model to estimate PROCESS_TOTAL Power
2025-01-14T16:04:32.406Z | I0114 16:04:32.406688       1 process_energy.go:130] Feature names: [bpf_cpu_time_ms]
2025-01-14T16:04:32.408Z | E0114 16:04:32.408215       1 node.go:145] grep cpuid command output failure: exit status 1
2025-01-14T16:04:32.408Z | E0114 16:04:32.408571       1 node.go:123] getCPUArch failure: open /sys/devices/cpu/caps/pmu_name: no such file or directory
2025-01-14T16:04:32.408Z | I0114 16:04:32.408619       1 process_energy.go:129] Using the Ratio Power Model to estimate PROCESS_COMPONENTS Power
2025-01-14T16:04:32.408Z | I0114 16:04:32.408628       1 process_energy.go:130] Feature names: [bpf_cpu_time_ms bpf_cpu_time_ms bpf_cpu_time_ms   gpu_compute_util]
2025-01-14T16:04:32.409Z | E0114 16:04:32.409801       1 node.go:145] grep cpuid command output failure: exit status 1
2025-01-14T16:04:32.410Z | E0114 16:04:32.410012       1 node.go:123] getCPUArch failure: open /sys/devices/cpu/caps/pmu_name: no such file or directory
2025-01-14T16:04:32.411Z | I0114 16:04:32.411706       1 regressor.go:276] Created predictor linear for trainer: "SGDRegressorTrainer"
2025-01-14T16:04:32.411Z | I0114 16:04:32.411726       1 model.go:125] Requesting for Machine Spec: &{genuineintel intel_core_ultra_7_155u 14 1 15 2700 2}
2025-01-14T16:04:32.411Z | I0114 16:04:32.411735       1 node_platform_energy.go:53] Using the Regressor/AbsPower Power Model to estimate Node Platform Power
2025-01-14T16:04:32.412Z | E0114 16:04:32.412799       1 node.go:145] grep cpuid command output failure: exit status 1
2025-01-14T16:04:32.413Z | E0114 16:04:32.412975       1 node.go:123] getCPUArch failure: open /sys/devices/cpu/caps/pmu_name: no such file or directory
2025-01-14T16:04:32.414Z | I0114 16:04:32.414428       1 regressor.go:276] Created predictor linear for trainer: "SGDRegressorTrainer"
2025-01-14T16:04:32.414Z | I0114 16:04:32.414444       1 regressor.go:276] Created predictor linear for trainer: "SGDRegressorTrainer"
2025-01-14T16:04:32.414Z | I0114 16:04:32.414446       1 regressor.go:276] Created predictor linear for trainer: "SGDRegressorTrainer"
2025-01-14T16:04:32.414Z | I0114 16:04:32.414448       1 regressor.go:276] Created predictor linear for trainer: "SGDRegressorTrainer"
2025-01-14T16:04:32.414Z | I0114 16:04:32.414451       1 model.go:125] Requesting for Machine Spec: &{genuineintel intel_core_ultra_7_155u 14 1 15 2700 2}
2025-01-14T16:04:32.414Z | I0114 16:04:32.414458       1 node_component_energy.go:57] Using the Regressor/AbsPower Power Model to estimate Node Component Power
2025-01-14T16:04:32.414Z | I0114 16:04:32.414494       1 prometheus_collector.go:95] Registered Container Prometheus metrics
2025-01-14T16:04:32.414Z | I0114 16:04:32.414508       1 prometheus_collector.go:100] Registered VM Prometheus metrics
2025-01-14T16:04:32.414Z | I0114 16:04:32.414514       1 prometheus_collector.go:104] Registered Node Prometheus metrics
2025-01-14T16:04:32.417Z | I0114 16:04:32.417076       1 exporter.go:194] starting to listen on 0.0.0.0:9102
2025-01-14T16:04:32.417Z | I0114 16:04:32.417357       1 exporter.go:208] Started Kepler in 392.947565ms
```
Particularly the Started Kepler in ... part. If you do not see that, you can try:
```sh
# Uninstall kepler release
helm uninstall kepler -n monitoring
# Run script again after a few seconds:
./keplerAndMonitoringChart.sh

# You can try this a few times (it sometimes took me more than 2 times before it worked).
# You can also try to delete the kepler-<string> pod (it will automatically create it again)
```
Then you again need to wait a while before it works, trying to restart Docker Desktop again maybe and even your computer again to see if that works.
Previous situation: in a previous situation I had to uninstall with helm a couple of times and then redeploy. Then I restarted Docker Desktop and tried again, with it not working yet. Then I tried to close everything on my computer and restart my computer. Then I started Docker Desktop again, but the first time it did not start, so I restarted Docker Desktop again and then when Kubernetes was running I performed several actions and then Kepler reported energy consumed for other containers (in this case only orchestrator and another time it was mostly sidecar) after a couple minutes. So, it seems that a restart of your computer works best for this if you know Kepler started and is running, since this worked for me on several occasions. This is maybe because it then restarts and reads the CPU or other metrics differently but I am not sure, but it works!  

See this guide for detailed information about Kepler metrics: https://sustainable-computing.io/design/metrics/

Now you are all set to monitor and measure energy consumption!


#### Setup Grafana loki and promtail
Grafana itself is already deployed when using Prometheus stack, see Prometheus setup section.

Grafana loki and promtail allow centralized log management for distributed systems. Grafana Loki is a log aggregation system designed to work seamlessly with Grafana. Promtail is an agent that collects logs from your systems and forwards them to Loki.

When running the above script, loki and promtail should be deployed from the monitoring chart with helm. 
Now, do the following steps to verify Loki is working:
1. Follow the steps to port-forward Grafana like above with Kepler.

2. Navigate to Grafana UI > Connections > Data sources > Verify Loki is present and opening it and clicking Test works (if pods are running in Kubernetes ofcourse).

3. Select Explore with the Loki data source and run the query: 
{job=~".+"}

4. You should now see logs present from the application, as this query lists all logs that have a job label with at least one character.

Additional information:
```sh
# You can port-forward loki with this command:
kubectl port-forward svc/loki 3100:3100 -n monitoring
# However, this is probably not required as you can collect logs without it as well, but if you ever need it you can use that command.
```