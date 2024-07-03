# cadvisor metrics not including label for container name
This issue was occurring because I had not deployed cadvisor as a separate daemonset in my Kubernetes cluster. Therefore, it did not display the metrics correctly, even though Kubelet contains cadvisor. So, you need to deploy cadvisor as a separate daemonset to allow it to gather metrics on all nodes/pods/containers, etc.

Firstly, add cavisor as a daemonset (this includes the namespace and serviceaccount), such as:
```yaml
# cadvisor (namespace, serviceaccount and daemonset)
apiVersion: v1
kind: Namespace
metadata:
  name: cadvisor
---

apiVersion: v1
kind: ServiceAccount
metadata:
  name: cadvisor
  namespace: cadvisor
---

apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: cadvisor
  namespace: cadvisor
  labels:
    name: cadvisor
spec:
  selector:
    matchLabels:
      name: cadvisor
  template:
    metadata:
      labels:
        name: cadvisor
    spec:
      serviceAccountName: cadvisor
      containers:
      - name: cadvisor
        image: {{ .Values.cadvisor.image.repository }}:{{ .Values.cadvisor.image.tag }}
        resources:
          requests:
            memory: {{ .Values.cadvisor.resources.requests.memory }}
            cpu: {{ .Values.cadvisor.resources.requests.cpu }}
          limits:
            memory: {{ .Values.cadvisor.resources.limits.memory }}
            cpu: {{ .Values.cadvisor.resources.limits.cpu }}
        args:
        # Housekeeping is the interval that cadvisor gathers metrics (Default is 1s, increase to reduce resource usage)
        - --housekeeping_interval=60s
        - --max_housekeeping_interval=60s
        # Disable not needed metrics (saves resources) 
        # If metrics are missing, see this link and remove the disable option here: https://github.com/google/cadvisor/blob/master/docs/storage/prometheus.md
        - --disable_metrics=advtcp,cpuLoad,cpu_topology,cpuset,hugetlb,memory_numa,network,oom_event,percpu,perf_event,process,referenced_memory,resctrl,sched,tcp,udp
        volumeMounts:
        - name: rootfs
          mountPath: /rootfs
          readOnly: true
        - name: var-run
          mountPath: /var/run
          readOnly: true
        - name: sys
          mountPath: /sys
          readOnly: true
        - name: docker
          mountPath: /var/lib/docker
          readOnly: true
        - name: disk
          mountPath: /dev/disk
          readOnly: true
        ports:
          - name: http
            containerPort: {{ .Values.cadvisor.service.port }}
            protocol: TCP
      automountServiceAccountToken: false
      terminationGracePeriodSeconds: 30
      volumes:
      - name: rootfs
        hostPath:
          path: /
      - name: var-run
        hostPath:
          path: /var/run
      - name: sys
        hostPath:
          path: /sys
      - name: docker
        hostPath:
          path: /var/lib/docker
      - name: disk
        hostPath:
          path: /dev/disk
```
Make sure that you deploy it as a helm chart, such as in the monitoring helm chart located in this project.

This is the .yaml file containing namespace.yaml, serviceaccount.yaml and daemonset.yaml from https://github.com/google/cadvisor/tree/master/deploy/kubernetes/base all in one, with the image changed to a newer one and including variables set in a helm chart:
![alt text](./assets/GoogleCadvisorKubernetesDeploy.png)

Then prometheus needs to be configured appropriately to scrape the metrics from cadvisor:
```sh
# Set variables for the paths (example with the monitoring chart path)
$monitoringChartsPath="/mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/charts/monitoring"
monitoringValues="$monitoringChartsPath/values.yaml"

# Add the job to the prometheus config file:
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

# Rerun/upgrade Prometheus stack with the file
helm upgrade -i prometheus prometheus-community/kube-prometheus-stack --namespace monitoring -f "$monitoringPath/prometheus-config.yaml"

# Upgrade/apply the helm chart for the monitoring release:
helm upgrade -i -f "$monitoringValues" monitoring $monitoringChartsPath

# Then delete the prometheus operator pod (recreates it automatically == restart pod)
kubectl delete pod prometheus-kube-prometheus-operator-<stringInPodName> -n monitoring
# e.g.: kubectl delete pod prometheus-kube-prometheus-operator-6554f4464f-x2dw9 -n monitoring

# Then port forward promtheus and see if it is working
kubectl port-forward svc/prometheus-kube-prometheus-prometheus -n monitoring 9090:9090
```
Go to the Prometheus UI and navigate to Status > Targets. Here you should see that cadvisor is in the targets:

![alt text](./assets/cadvisorInPrometheusTargetsDown.png)

At first it will say down/unhealthy, because it is still initializing. (Except if there are errors shown). In a minute (you could try refreshing the page to see it faster) it should say up and when it says you can see something like this:

![alt text](./assets/cadvisorInPrometheusTargetsUp.png)

Then you can see that the target is up and new metrics have been collected. Then you can go to /graph in the Prometheus UI to view the changes:

```sh
# There are different metrics available now for this metric example, such as this format:
container_cpu_system_seconds_total{id="/", instance="10.244.0.80:8080", job="cadvisor"}

# Or this format:
container_cpu_system_seconds_total{id="/kubepods.slice/kubepods-besteffort.slice/kubepods-besteffort-pod08645525_d2f6_45db_a76a_ef770b179f8d.slice", instance="10.244.0.80:8080", job="cadvisor"}

# Or this format
container_cpu_system_seconds_total{container_label_annotation_kubernetes_io_config_seen="2024-07-02T05:26:47.297169660Z", container_label_annotation_kubernetes_io_config_source="api", container_label_app="grafana", container_label_io_kubernetes_container_name="POD", container_label_io_kubernetes_docker_type="podsandbox", container_label_io_kubernetes_pod_name="grafana-864bdb476c-qklw6", container_label_io_kubernetes_pod_namespace="core", container_label_io_kubernetes_pod_uid="0b973a09-283f-4fd7-a890-e3cfdef48af4", container_label_pod_template_hash="864bdb476c", id="/kubepods.slice/kubepods-besteffort.slice/kubepods-besteffort-pod0b973a09_283f_4fd7_a890_e3cfdef48af4.slice/docker-f4cbc2b4601ad7f825435098358f5aefa18abdb9332098400da0973893a3b8f2.scope", image="registry.k8s.io/pause:3.9", instance="10.244.0.80:8080", job="cadvisor", name="k8s_POD_grafana-864bdb476c-qklw6_core_0b973a09-283f-4fd7-a890-e3cfdef48af4_2"}

# This is the format you are looking for, as it contains the name of the container (container_label_io_kubernetes_container_name="linkerd-proxy"):
container_cpu_system_seconds_total{container_label_annotation_io_kubernetes_container_hash="3a050d51", container_label_annotation_io_kubernetes_container_ports="[{"name":"linkerd-proxy","containerPort":4143,"protocol":"TCP"},{"name":"linkerd-admin","containerPort":4191,"protocol":"TCP"}]", container_label_annotation_io_kubernetes_container_restartCount="2", container_label_annotation_io_kubernetes_container_terminationMessagePath="/dev/termination-log", container_label_annotation_io_kubernetes_container_terminationMessagePolicy="FallbackToLogsOnError", container_label_annotation_io_kubernetes_pod_terminationGracePeriod="30", container_label_io_kubernetes_container_logpath="/var/log/pods/linkerd_linkerd-proxy-injector-67945967d6-r9vg7_3560a86c-7de3-448d-b452-68d50f15e607/linkerd-proxy/2.log", container_label_io_kubernetes_container_name="linkerd-proxy", container_label_io_kubernetes_docker_type="container", container_label_io_kubernetes_pod_name="linkerd-proxy-injector-67945967d6-r9vg7", container_label_io_kubernetes_pod_namespace="linkerd", container_label_io_kubernetes_pod_uid="3560a86c-7de3-448d-b452-68d50f15e607", container_label_io_kubernetes_sandbox_id="37e308d755f551e5ac00565d3daf4d7fb58c67993d3913b7bbe293e426cccea3", id="/kubepods.slice/kubepods-besteffort.slice/kubepods-besteffort-pod3560a86c_7de3_448d_b452_68d50f15e607.slice/docker-877f95410fc8ff758ceb4525bf4b4d6452804e2539d3b48d77ec5721019a3469.scope", image="sha256:c50fbb2aec4d19e6b5b03e7d13da23145f8c50e1f333199f5a2a446d8e37bcf7", instance="10.244.0.80:8080", job="cadvisor", name="k8s_linkerd-proxy_linkerd-proxy-injector-67945967d6-r9vg7_linkerd_3560a86c-7de3-448d-b452-68d50f15e607_2"}
```
The final example shows the linkerd-proxy name as the name of the container (container_label_io_kubernetes_container_name="linkerd-proxy"). This is the name you want to see, because as you can see in the image below:

![alt text](./assets/linkerd-proxyContainer.png)

The 'linkerd-proxy-injector-67945967d6-r9vg7' pod contains the container with name 'linkerd-proxy'. This can be seen by the following information in the last output:
container_label_io_kubernetes_pod_name="linkerd-proxy-injector-67945967d6-r9vg7"

This is also what it should be for grouping the results by name, then you can filter by containers for example:

![alt text](./assets/cadvisorFilterByContainer.png)

In this case you can see that we filter by 'container_label_io_kubernetes_container_name', which is equal to the container name that is provided by cadvisor in the used version. This is how you can filter these results by container.





# Too many files open, pod not starting (or other unexplainable errors)
This should NOT be done with all errors! An error like this for example:
```sh
0/1 nodes are available: persistentvolumeclaim "rabbit-pvc" not found. preemption: 0/1 nodes are available: 1 Preemption is not helpful for scheduling.
```
Is descriptive and is not unexplainable. Here you need to create the Persistent Volume Claim (PVC) rabbit-pvc for it to work and you should not apply the below solutions, because that will not work. So, only apply the below solutions when the error is unexplainable and you do not really know what to do. This is an easy fix that might be worth a try.

The example error for this section is:
```sh
E0702 14:44:35.994664       1 manager.go:294] Registration of the raw container factory failed: inotify_init: too many open files
F0702 14:44:35.994677       1 cadvisor.go:170] Failed to start manager: inotify_init: too many open files
```
The container/pod itself might say something like 'crashloopbackof ...' or something else related, but when I took a look at the logs and then the container, it said the above error.

This occured after uninstalling using helm (uninstall monitoring chart). Then re-applying (helm upgrade) and the issue was there.
What fixed it was that I left the issue for about a day. Then I came back and started up minikube and all of a sudden it worked! So, when you restart minikube it fixes a lot of these weird issues, because it then re-initializes a lot of resources and that can fix these issues, so for example run:
```sh
# What you can do first is to restart the pod/service/etc... This is an example of a pod restart:

# If that does not work you can try to restart minikube
# Stop minikube
minikube stop

# Wait for about 30 seconds

# Restart minikube
minikube start
```
You may try this several times, since it does not always work the first time. So, you can try to do it a couple of times before giving up on this fix, waiting some time in between. The waiting in between is very important, since this lets the resources and operations cool down. For example, start it, wait about a minute, then stop and wait some time again and retry.

**This approach can fix a lot of problems that may occur that you do not know why they are occurring. This is an easy method to try before applying drastic changes, because this fixes a lot of those issues most of the time.**


I also tried to reduce the amount of resources it consumed by adding these arguments:
```yaml
# args only:
        args:
        # Housekeeping is the interval that cadvisor gathers metrics (Default is 1s, increase to reduce resource usage)
        - --housekeeping_interval=60s
        - --max_housekeeping_interval=60s
        # Disable not needed metrics (saves resources) 
        # If metrics are missing, see this link and remove the disable option here: https://github.com/google/cadvisor/blob/master/docs/storage/prometheus.md
        - --disable_metrics=advtcp,cpuLoad,cpu_topology,cpuset,hugetlb,memory_numa,network,oom_event,percpu,perf_event,process,referenced_memory,resctrl,sched,tcp,udp

# Full daemonset:
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: cadvisor
  namespace: cadvisor
  labels:
    name: cadvisor
spec:
  selector:
    matchLabels:
      name: cadvisor
  template:
    metadata:
      labels:
        name: cadvisor
    spec:
      serviceAccountName: cadvisor
      containers:
      - name: cadvisor
        image: {{ .Values.cadvisor.image.repository }}:{{ .Values.cadvisor.image.tag }}
        resources:
          requests:
            memory: {{ .Values.cadvisor.resources.requests.memory }}
            cpu: {{ .Values.cadvisor.resources.requests.cpu }}
          limits:
            memory: {{ .Values.cadvisor.resources.limits.memory }}
            cpu: {{ .Values.cadvisor.resources.limits.cpu }}
        args:
        # Housekeeping is the interval that cadvisor gathers metrics (Default is 1s, increase to reduce resource usage)
        - --housekeeping_interval=60s
        - --max_housekeeping_interval=60s
        # Disable not needed metrics (saves resources) 
        # If metrics are missing, see this link and remove the disable option here: https://github.com/google/cadvisor/blob/master/docs/storage/prometheus.md
        - --disable_metrics=advtcp,cpuLoad,cpu_topology,cpuset,hugetlb,memory_numa,network,oom_event,percpu,perf_event,process,referenced_memory,resctrl,sched,tcp,udp
        volumeMounts:
        - name: rootfs
          mountPath: /rootfs
          readOnly: true
        - name: var-run
          mountPath: /var/run
          readOnly: true
        - name: sys
          mountPath: /sys
          readOnly: true
        - name: docker
          mountPath: /var/lib/docker
          readOnly: true
        - name: disk
          mountPath: /dev/disk
          readOnly: true
        ports:
          - name: http
            containerPort: {{ .Values.cadvisor.service.port }}
            protocol: TCP
      automountServiceAccountToken: false
      terminationGracePeriodSeconds: 30
      volumes:
      - name: rootfs
        hostPath:
          path: /
      - name: var-run
        hostPath:
          path: /var/run
      - name: sys
        hostPath:
          path: /sys
      - name: docker
        hostPath:
          path: /var/lib/docker
      - name: disk
        hostPath:
          path: /dev/disk
```


If this does not fix the issue, you may try to analyse the issue further:
```sh
# Get the pods from the namespace:
kubectl get pods -n cadvisor

# Get the uulimit (max number of files open setting):
kubectl exec -it -n cadvisor <pod-name> -- sh -c "ulimit -n"
# In my case it displayed: 1048576, which is a more than high enough number for cadvisor probably. So, that is why it worked again when I restarted minikube.
# If this displays something very low, then you might need to increase this.
```
To increase the ulimit, you can try a few different things:
```sh
# Try to increase the ulimit in the daemonset/pod/etc..., such as adding this:
    spec:
      securityContext:
        sysctls:
        - name: fs.file-max
          value: "1048576"
# After that you can try to check the ulimit again to see if the changes have applied:
kubectl exec -it -n cadvisor <pod-name> -- sh -c "ulimit -n"



# Or you can try to increase the docker ulimit globally:
# Open minikube ssh
minikube ssh
# Check docker configurations
ps aux | grep dockerd
# Example display:
root         973  5.5  1.2 8545664 100112 ?      Ssl  12:15   1:34 /usr/bin/dockerd -H tcp://0.0.0.0:2376 -H unix:///var/run/docker.sock --default-ulimit=nofile=1048576:1048576 --tlsverify --tlscacert /etc/docker/ca.pem --tlscert /etc/docker/server.pem --tlskey /etc/docker/server-key.pem --label provider=docker --insecure-registry 10.96.0.0/12
root        1302  4.3  0.3 1278400 31388 ?       Ssl  12:15   1:15 /usr/bin/cri-dockerd --container-runtime-endpoint fd:// --pod-infra-container-image=registry.k8s.io/pause:3.9 --network-plugin=cni --hairpin-mode=hairpin-veth
docker     15208  0.0  0.0   3604  1652 pts/1    S+   12:44   0:00 grep --color=auto dockerd
# Here you can see that the global default ulimit is: --default-ulimit=nofile=1048576:1048576
# But you can increase this manually by doing this for example (or even higher):
minikube start --docker-opt="default-ulimit=nofile=102400:102400"
# You may need to restart minikube or even delete and then recreate minikube again
```

And if this does not fix the issue, you may need to analyse the issue further and see if you can find a solution on the internet or using AI for example.




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




# Minikube status and logs for troubleshooting
You can use minikube status to view the status of the Kubernetes cluster to see if everything is running for example:
```sh
minikube status
```

If a service does not work or takes unusually long for example, you can view the logs and pods using kubectl:
```sh
# Example for minikube dashboard (this works with all other namespaces/pods/etc.., if you replace it with the corresponding names)

# You can get the pods using this command (namespace = kubernetes-dashboard)
kubectl get pods -n kubernetes-dashboard

# Check services and endpoints
kubectl get svc -n kubernetes-dashboard
kubectl get endpoints -n kubernetes-dashboard

# Check logs
kubectl logs -n kubernetes-dashboard <kubernetes-dashboard-pod-name>

# Restart dashboard service
kubectl delete pod -n kubernetes-dashboard <kubernetes-dashboard-pod-name>
```




# Using Kubernetes dashboard for troubleshooting
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
# Run the script to apply the configmap and delete the pod (recreates it automatically == restart pod)
# Replace with real string-id of the pod name (e.g. prometheus-server-5787759b8c-46gwn)
./reconfigurePrometheusServer.sh prometheus-server-string-id

# Kubernetes automatically restarted this pod for me and then it worked!
```



# Prometheus not showing Target (Status > Targets in Prometheus UI), while it is displayed in my configmap
This is due to the reason that you may use Kubernetes service discovery to find pods. In this example you can see a prometheus config for the job name that adds the data for cadvisor:
```yaml
global:
  scrape_interval: 1m
  evaluation_interval: 1m
  # Avoids cadvisor to exceed the timeout range for example (increase when jobs are exceeding this time)
  scrape_timeout: 25s

scrape_configs:
  # Job to gather metrics like CPU and memory using cadvisor daemonset
  - job_name: 'cadvisor'
    # Configures Kubernetes service discovery to find pods
    kubernetes_sd_configs:
      - role: pod
    # Configures relabeling rules
    relabel_configs:
      # Keep only pods with the label app=cadvisor (otherwise all other metrics will be included, but you only want cadvisor metrics)
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

![alt text](./assets/PrometheusNoResultsQueryTimeinterval.png)

To fix this, you can try to increase the time to find data:

![alt text](./assets/PrometheusNoResultsFix.png)

Here you can see that there are results available (if not you can try to keep increasing the interval until you have data, such as 3m, 5m, 10m, etc.). This issue is related to the (global or job specific) configuration of prometheus. For example, if you have a scrape interval of 1m, then there is probably no data available at the time interval of 1m. 



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



# Cluster role exists or other data exists
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