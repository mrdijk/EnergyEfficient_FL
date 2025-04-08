# Troubleshooting
This file describes any possible problems that occurred during our setup of the Kubernetes cluster.

Note: do not forget to upload the kubespray changes to the remote host controle plane (in this case node1)! Otherwise, the changes will not apply. For example, reupload the whole kubespray file with several files changed, and only a file when only one file changed, etc.


## Calico-kube-controllers not working/kube-proxy problems
### Initial problem
The inital error for calico-kube-controllers pod was:
```sh
│ 2025-04-08 09:22:49.914 [ERROR][1] kube-controllers/client.go 320: Error getting cluster information config ClusterInformation="default" error=Get "http ││ s://10.233.0.1:443/apis/crd.projectcalico.org/v1/clusterinformations/default": dial tcp 10.233.0.1:443: connect: no route to host 
```
This was likely caused due to no route available, which could be caused by the kube-apiserver not reachable for example.

### Kube-proxy problem with old ubuntu version
When looking at kube-proxy, I found this (even though kube-proxy pods were running and ready):
```sh
││ "Failed to execute iptables-restore" err=< 
││     exit status 2: Warning: Extension MARK revision 0 not supported, missing kernel module?                                                              
││     ip6tables-restore v1.8.9 (nf_tables): unknown option "--xor-mark"
││     Error occurred at line: 11
││     Try ip6tables-restore -h' or 'ip6tables-restore --help' for more information
││  > ipFamily="IPv6" rules="*nat\n:KUBE-SERVICES - [0:0]\n:KUBE-POSTROUTING - [0:0]\n:KUBE-NODE-PORT - [0:0]\n:KUBE-LOAD-BALANCER - [0:0]\n:KUBE-MARK-MASQ
```
This was likely the main issue, since the routes were not correctly available.

I tried several things, such as changing from kube_proxy_mode "ipvs" to "iptables", but that did nothing and was not the issue, so staying on the default "ipvs" for kubespray was best here. The kube_proxy_mode to iptables was not changing with only running cluster.yml, so I had to do reset.yml and then cluster.yml. Delete and recreate slice and then run every step again, also applied the changes. Also, running in dual-stack mode for kube-proxy is the default and is also fine (also checked this on localhost setup with Docker Desktop and that also uses dual-stack mode for IPv4 and IPv6, so that is also fine).
TODO: it only worked with recreating slice and then running it, then it changed to:
TASK [network_plugin/calico : Wait for calico kubeconfig to be created] ************************************************************************************
fatal: [node3]: FAILED! => {"changed": false, "elapsed": 300, "msg": "Timeout when waiting for file /etc/cni/net.d/calico-kubeconfig"}
fatal: [node2]: FAILED! => {"changed": false, "elapsed": 300, "msg": "Timeout when waiting for file /etc/cni/net.d/calico-kubeconfig"}

Eventually, I changed from default_ubuntu_22 image to default_ubuntu_24 image for the VM. This fixed the ip6tables issue, likely because this newer image has support for that and is better compatible with the version of kubespray I use, which is also relatively new and close to 2024. 

### Next issue: still calico not working and initial kube-proxy problem
However, then a different issue arose that likely still caused the calico problem above:
```sh
E0408 09:11:02.206197       1 server.go:424] "Healthz server failed" err="failed to start proxier healthz on 0.0.0.0:10256: listen tcp 0.0.0.0:10256: bind: address already in ││  use" logger="UnhandledError"
E0408 09:11:02.206520       1 server.go:466] "Unhandled Error" err="starting metrics server failed: listen tcp 127.0.0.1:10249: bind: address already in ││  use" logger="UnhandledError"            
```
However, this was not an issue, since the pod was running and ready, and this was something likely due to the restart behaviour in kubernetes, see:
```sh
# Check the process running on the same port:
sudo lsof -i :10256 -i :10249
# This gave back:
COMMAND     PID USER   FD   TYPE  DEVICE SIZE/OFF NODE NAME
kube-prox 67320 root   10u  IPv4 1302952      0t0  TCP localhost.localdomain:10249 (LISTEN)
kube-prox 67320 root   11u  IPv6 1302050      0t0  TCP *:10256 (LISTEN)
# So, that means that it was kube-proxy itself and it likely caused something with the restart behaviour the first time.

# So, after restarting the kube-proxy pods with:
kubectl -n kube-system delete pod -l k8s-app=kube-proxy
# It did not show the same errors in the logs and the errors above were gone, confirming it was something with the restart behaviour. After a restart the first command also gave back different PIDs, confirming different processes were made with the restart of the pods.

# Check connectivity with kube-apiserver on each node via SSH into the VM:
curl -k https://10.233.0.1:443
# This gave back 403 Forbidden, which confirms the node can route to the kube-apiserver, confirming:
# The Kubernetes API service is working, and kube-proxy is correctly exposing the API server via the ClusterIP service.

# Test connection from a temporary pod:
kubectl run test-pod --rm -it --image=busybox --restart=Never -- sh
# Ran:
ping 10.233.0.1
# Result: nothing was returned/given back until eventual timeout
# And ran:
wget --spider --timeout=3 https://10.233.0.1
# Result:
# Connecting to 10.233.0.1 (10.233.0.1:443)
# wget: can't connect to remote host (10.233.0.1): No route to host

# This confirmed that pod-level routing is broken, since they cannot reach the kube-apiserver.
# Tried restarting/resyncing cleanly with Calico for pod-level routing:
kubectl -n kube-system delete pod -l k8s-app=calico-node
kubectl -n kube-system delete pod -l k8s-app=calico-kube-controllers
# Then retested connection with steps above from a temporary pod, but same result.
```

### Further issue: pod-level routing broken
```sh
# TODO: further steps
# TODO: problem now: But pods (CoreDNS, Calico) cannot reach the same service IP
# TODO: final problem: pod-level routing is broken:

```
TODO: this is likely not a problem I noticed, since it is running afterwards?

TODO: explain further what the issue was and how we solvd it.
TODO: can use this in k8s-net-calico.yml to ensure it uses the correct one, but not necessary yet:
calico_ip_auto_method: "interface=enp7s0"
TODO: try this when others fail.


### Additional helpful commands found during the process
Additional helpful commands:
```sh
# Test connection inside the Kubernetes cluster
# Run a test pod to execute commands in it in the control plane node (node1)
kubectl run test-pod --rm -it --image=busybox --restart=Never -- sh
# Inside it run:
nslookup kubernetes.default
# If you get something like this you know DNS is not correctly running:
;; connection timed out; no servers could be reached
# Also, run this to connect to something
wget --spider --timeout=3 https://kubernetes.default.svc.cluster.local
# If you get something like this, you know it is not correct:
wget: bad address 'kubernetes.default.svc.cluster.local'
# Another example of connecting to something, in this case the kube-apiserver:
wget --spider https://10.233.0.1:443
# Type this and press enter to exit:
exit


# Editing configurations:
# Manual steps to change a config map (not recommended, use the cluster deploy and change variables before running the cluster.yml)
# ConfigMap of pods named kube-proxy
kubectl -n kube-system get configmap kube-proxy -o yaml
# Edit manually:
kubectl -n kube-system edit configmap kube-proxy
# Press i to enter insert mode and make changed. Press Esc to exit instert mode and type :wq and Enter to write (=save) and quit
# Restart pods
kubectl -n kube-system delete pods -l k8s-app=kube-proxy
```


## etcd problems:
If you encounter problems with etcd, such as during kubespray cluster configuration, these steps might help:
```sh
# SSH into the control plane using the SSH command from earlier for node1

# Show status
sudo systemctl status etcd.service
# Show last 50 log lines
sudo journalctl -u etcd.service -n 50 --no-pager
# These logs can be used for further debugging
# You can use this command to see some configurations for example:
sudo cat /etc/systemd/system/etcd.service

# Examples:
{"level":"warn","ts":"2025-04-04T09:31:28.416172Z","caller":"etcdmain/etcd.go:75","msg":"failed to verify flags","error":"invalid value \"https://2001:610:2d0:fabc:f816:3eff:fe65:a464:2380\" for ETCD_LISTEN_PEER_URLS: URL address does not have the form \"host:port\": https://2001:610:2d0:fabc:f816:3eff:fe65:a464:2380"}
# This was due to IPv6 addresses having a specific format. In FABRIC, we use IPv6, such as: 2001:610:2d0:fabc:f816:3eff:fe65:a464
# So, the IP should be enclosed in [] to make that work. However, more broad problems with using IPv6 was discovered, so a different solution was done, which is now the current setup.
```