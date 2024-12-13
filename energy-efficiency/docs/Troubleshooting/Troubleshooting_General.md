# Troubleshooting
This file contains documentation about Kubernetes related problems that I found very useful during my first time working with Kubernetes. It probably does not contain detailed information about general topics, like how Kubernetes works, because this is all available in the Kubernetes documentation for example. However, things that are not generally available in documentation and things I found very helpful during my time working with Kubernetes are explained (and fixed) here. So, use the documentation for general things, such as Kubernetes, Helm, etc., but for more understanding or useful steps, use this document.

Do NOT add unnecessary extra information here, because that will only consume time, while it is available in the general documentation of Kubernetes for example. Only add information that you find very helpful and only when you have time, because this is just extra information!

Additional files are present for other topics that are not general.


# Error response from daemon: path / is mounted on / but it is not a shared or slave mount
This is about the following error:
```sh
Error: failed to start container "node-exporter": Error response from daemon: path / is mounted on / but it is not a shared or slave mount
Back-off restarting failed container node-exporter in pod prometheus-prometheus-node-exporter-wqldj_monitoring(a15c3f1b-d8dc-4f1b-8425-48b9f5b95243)
```
This error occurred to me when I worked with Prometheus stack and I installed it using Helm.
This error occurs because the node-exporter container in the Prometheus stack is trying to access host-level metrics by mounting the / directory. Docker Desktop on macOS or Windows does not provide direct access to the host filesystem in a way that supports this setup.
This is not an issue of node exporter or helm chart or Kubernetes or docker but a limitation of docker desktop. Only people using Kubernetes on the docker desktop should be the ones facing the issue. See for example: https://stackoverflow.com/questions/70556984/kubernetes-node-exporter-container-is-not-working-it-shows-this-error-message

To fix this, you can do different things, this worked for me:
```sh
# Create a values.yaml file, or add it to the prometheus configuration.yaml file you have:
prometheus-node-exporter:
  hostRootFsMount:
    enabled: false
# Then apply the file using kubectl, or using the upgrade/install with helm

# Or use a command, but the above is recommended, as you do not have to do this everytime:
helm upgrade prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --set prometheus-node-exporter.hostRootFsMount.enabled=false
```

But keep in mind, this is a workaround and NOT a solution. It is a limitation for Docker Desktop, but when you use the above workaround, the node-exporter won't be able to collect all data needed for grafana dashboards and for alerts, because it is disabling mount propagation.
However, this is a Docker Desktop limitation, which means that it should probably not occur in the production environment (unless your production environment is Docker Desktop). So, for local development you can fix it with the above workaround, but in the production environment you can enable it again so that it works fine in the production environment of Kubernetes. 





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

# Or with Docker Desktop: Open Docker Desktop and Right-click the Docker Desktop icon in the system tray and select Quit Docker Desktop.
# This will restart Docker Desktop, including the Kubernetes cluster. Then you can open Docker Desktop again to start it.
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

Or you could use Kubernetes Dashboard and view the logs there.




# Using Kubernetes dashboard for troubleshooting
Run
Open the dashboard. Here you can see pods running and debug it that way. For example, if you click on the three dots and select "Logs" you can view the logs of the different containers in the pod. For instance, the following error was present in one of my earlier issues:
```
ts=2024-07-01T15:35:06.232Z caller=main.go:537 level=error msg="Error loading config (--config.file=/etc/config/prometheus-config.yaml)" file=/etc/config/prometheus-config.yaml err="parsing YAML file /etc/config/prometheus-config.yaml: yaml: unmarshal errors:\n  line 5: field global already set in type config.plain"
```
Then I viewed the configMaps in the Kubernetes dashboard under Config and Storage section > Config Maps. Here I saw "prometheus-server" config map had two global sections. I then fixed my prometheus-config.yaml file and updated it in the Kubernetes cluster. Updating it involved applying the new configMap and then deleting the pod (recreates it automatically == restart pod), and Kubernetes will then automatically restart the pod for me.

This example showed how you can use Kubernetes Dashboard to locate and analyze errors. You can also search the error on the internet and look at for example StackOverflow or something related to find earlier people having the same issue. And/or you could ask AI.



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

# Or with Docker Desktop: Open Docker Desktop and Right-click the Docker Desktop icon in the system tray and select Quit Docker Desktop.
# This will restart Docker Desktop, including the Kubernetes cluster. Then you can open Docker Desktop again to start it.
```

If something else is taking very long, such as the port forward operation, you could try restarting wsl:
```sh
# exit wsl session (if you have a wsl session (terminal) open)
exit
# Restart wsl
wsl --shutdown

# Restart Docker Desktop to start the Docker engine (Open Docker Desktop and Right-click the Docker Desktop icon in the system tray and select Quit Docker Desktop.
# This will restart Docker Desktop, including the Kubernetes cluster.)
# Restarting Kubernetes on Docker Desktop will be done automatically when restarting Docker Desktop.
# Restart Kubernetes (minikube)
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

# Or with Docker Desktop: Open Docker Desktop > Settings > select the Kubernetes tab > Reset Kubernetes Cluster.
```


## Script file (.sh) error
Error (or similar):
```sh
./2_prepareRabbitMQ.sh: line 1: $'\r': command not found
./2_prepareRabbitMQ.sh: line 3: $'\r': command not found
./2_prepareRabbitMQ.sh: line 47: syntax error: unexpected end of file

# Or:
-bash: ./prometheus.sh: /bin/bash^M: bad interpreter: No such file or directory
```
This suggests that the file has Windows style line endings (CRLF) instead of Unix/Linux-style line endings (LF).

This can be fixed by using dos2unix package:
```sh
# Install first if necessary
sudo apt-get update
sudo apt-get install dos2unix

# Convert script file to LF
# e.g.: dos2unix /mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/energy-efficiency/scripts/2_prepareRabbitMQ.sh
# Or from current path e.g.: dos2unix ./<scriptName>.sh
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

# Or with Docker Desktop: Open Docker Desktop and Right-click the Docker Desktop icon in the system tray and select Quit Docker Desktop.
# This will restart Docker Desktop, including the Kubernetes cluster. Then you can open Docker Desktop again to start it.
```
Possibly also restarting other things, such as forwarding Grafana.