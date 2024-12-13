# Prometheus does not see a Target
For example, when you go to the Prometheus UI > Status > Targets and you do not see it, or it is empty when you select it, it means that it is not properly configured or cannot be discovered by Prometheus. When I had this issue, it was because I discovered the pod using the label: name:
```yaml
prometheus:
  prometheusSpec:
    additionalScrapeConfigs:
      # Job to gather metrics like CPU and memory using cadvisor daemonset
      - job_name: 'cadvisor'
        # Configures Kubernetes service discovery to find pods
        kubernetes_sd_configs:
          - role: pod
        # Configures relabeling rules
        relabel_configs:
          # Keep only pods with the label name=cadvisor (otherwise all other metrics will be included, but you only want cadvisor metrics)
          # Make sure that the name label is present in the pod (or in this case daemonset) you are creating! Otherwise, Prometheus cannot see it
          - source_labels: [__meta_kubernetes_pod_label_name]
            action: keep
            regex: cadvisor
          # Replace target with pod IP and port 8080 (where cadvisor runs)
          - source_labels: [__meta_kubernetes_pod_ip]
            action: replace
            target_label: __address__
            regex: (.+)
            replacement: ${1}:8080
          # No custom labels/replacements are set here (do NOT change this, because now it works!), so that the defaults of 
          # cadvisor are used! For example, you can group by name of the container with: container_label_io_kubernetes_container_name
```
However, I had the daemonset configured like this (the label part):
```yaml
spec:
  selector:
    matchLabels:
      k8s-app: cadvisor
```
As you can see, I did not have the label 'name'. So, I fixed it with changing the label to name:
```yaml
spec:
  selector:
    matchLabels:
      name: cadvisor
```
And then I redeployed/re-applied the daemonset and then it worked!

# Prometheus not showing Target (Status > Targets in Prometheus UI), while it is displayed in my configmap
This is due to the reason that you may use Kubernetes service discovery to find pods. In this example you can see a prometheus config for the job name that adds the data for cadvisor:
```yaml
prometheus:
  prometheusSpec:
    # Set global scrape interval and scrape timeout
    # Set this to higher to avoid cadvisor sometimes timing out
    scrapeInterval: "30s"
    scrapeTimeout: "25s"
    evaluationInterval: "1m"

    # Additional scrape configs (on top of already present/default ones)
    additionalScrapeConfigs:
      # Job to gather metrics like CPU and memory using cadvisor daemonset
      - job_name: 'cadvisor'
        # Configures Kubernetes service discovery to find pods
        kubernetes_sd_configs:
          - role: pod
        # Configures relabeling rules
        relabel_configs:
          # Keep only pods with the label app=cadvisor (otherwise all other metrics will be included, but you only want cadvisor metrics)
          # Make sure that the name label is present in the pod (or in this case daemonset) you are creating! Otherwise, Prometheus cannot see it
          - source_labels: [__meta_kubernetes_pod_label_name]
            action: keep
            regex: cadvisor
          # Replace target with pod IP and port 8080 (where cadvisor runs)
          - source_labels: [__meta_kubernetes_pod_ip]
            action: replace
            target_label: __address__
            regex: (.+)
            replacement: ${1}:8080
          # No custom labels/replacements are set here (do NOT change this, because now it works!), so that the defaults of 
          # cadvisor are used! For example, you can group by name of the container with: container_label_io_kubernetes_container_name
```
Here you can see that 'kubernetes_sd_configs' is used. The issue I had was that I first used:
```yaml
- source_labels: [__meta_kubernetes_pod_label_app]
```
Here I used app instead of name for the labels to discover pods. However, that label did not exist. You can list labels of the pods using this command:
```sh
# Replace the part after -n with the namespace the pod is in
kubectl get pods -n kube-system --show-labels

# Or to show all namespaces labels:
kubectl get pods --all-namespaces --show-labels

# Example output:
NAME                               READY   STATUS    RESTARTS       AGE    LABELS
cadvisor-p7bbr                     1/1     Running   1 (98m ago)    100m   controller-revision-hash=7d9b7fb895,name=cadvisor,pod-template-generation=1
coredns-7db6d8ff4d-d86gf           1/1     Running   2 (125m ago)   16h    k8s-app=kube-dns,pod-template-hash=7db6d8ff4d
etcd-minikube                      1/1     Running   2 (125m ago)   16h    component=etcd,tier=control-plane
kube-apiserver-minikube            1/1     Running   2 (125m ago)   16h    component=kube-apiserver,tier=control-plane
kube-controller-manager-minikube   1/1     Running   2 (125m ago)   16h    component=kube-controller-manager,tier=control-plane
kube-proxy-q5v85                   1/1     Running   2 (125m ago)   16h    controller-revision-hash=79cf874c65,k8s-app=kube-proxy,pod-template-generation=1
kube-scheduler-minikube            1/1     Running   2 (125m ago)   16h    component=kube-scheduler,tier=control-plane
storage-provisioner                1/1     Running   3 (125m ago)   16h    addonmanager.kubernetes.io/mode=Reconcile,integration-test=storage-provisioner
```
In the example output you can see that only the name label is present for cadvisor, and not the app label. Therefore, I changed the label to the original yaml code snippet above and restarted Prometheus (see issue below: this restarts Prometheus (1. create/update configmap/2. delete prometheus-server pod to automatically restart it./3. port forward to view changes)).



# Prometheus query not returning any results, while you do expect results
This can happen if you have a time included, such as a time interval of 1m:

![alt text](../assets/PrometheusNoResultsQueryTimeinterval.png)

To fix this, you can try to increase the time to find data:

![alt text](../assets/PrometheusNoResultsFix.png)

Here you can see that there are results available (if not you can try to keep increasing the interval until you have data, such as 3m, 5m, 10m, etc.). This issue is related to the (global or job specific) configuration of prometheus. For example, if you have a scrape interval of 1m, then there is probably no data available at the time interval of 1m. 