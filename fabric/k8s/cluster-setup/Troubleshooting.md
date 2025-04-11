# Troubleshooting
This file describes any possible problems that occurred during our setup of the Kubernetes cluster.

Note: do not forget to upload the kubespray changes to the remote host controle plane (in this case node1)! Otherwise, the changes will not apply. For example, reupload the whole kubespray file with several files changed, and only a file when only one file changed, etc.

See for more information: https://kubernetes.io/docs/tasks/debug/


## Calico-kube-controllers not working/kube-proxy problems
Problem:
```sh
W0410 12:09:08.788591       1 reflector.go:535] pkg/mod/k8s.io/client-go@v0.28.15/tools/cache/reflector.go:229: failed to list *v1.ConfigMap: Get "https://10.96.0.1:443/api/v1/namespaces/calico-system/conf ││ igmaps?fieldSelector=metadata.name%3Dactive-operator&limit=500&resourceVersion=0": dial tcp 10.96.0.1:443: connect: network is unreachable
```
This was fixed by manually running on the node in SSH:
```sh
sudo sysctl -w net.ipv4.ip_forward=1
# Add the service subnet to the ip routes
sudo ip route add 10.96.0.0/12 dev enp7s0
# Restart pod for calico tigera-operator
kubectl delete pod -n tigera-operator -l k8s-app=tigera-operator
```
However, we later found out that this fix causes more problems later, since the route of the services in Kubernetes are now routed through the physical interface (enp7s0) we created in FABRIC, causing the following error, since this interface does not know any route in the subnet: 10.96.0.0/12:
```sh
2025-04-10 06:49:10.689 [ERROR][1] kube-controllers/client.go 320: Error getting cluster information config ClusterInformation="default" error=Get "https://10.96.0.1:443/apis/crd.projectcalico.org/v1/clust ││ erinformations/default": dial tcp 10.96.0.1:443: connect: no route to host
```

What we did to fix it on FABRIC:
```sh
# Show all, including local, useful for seeing all the routes on a node:
ip route show table all
# Only show the important ones, this is usually enough:
ip route
# Debugging:
# On control plane, allow scheduling for debugging: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm#control-plane-node-isolation
kubectl taint nodes node1 node-role.kubernetes.io/control-plane-
# Test connection inside the Kubernetes cluster
# Run a test pod to execute commands in it in the control plane node (node1)
kubectl run test-pod --rm -it --image=busybox --restart=Never -- sh
# Here you can test connectivity from a pod and other things from a pod for example

# Eventual fix:
# Add the route for the Kubernetes service subnet, otherwise, it cannot reach that:
sudo ip route add 10.96.0.0/12 dev enp7s0
# This fix essentially says: Please send traffic to that subnet out through enp7s0 directly, and trust the network 
# or NAT/iptables to handle it from there. And the iptables are correctly created with kube-proxy, which is why it works from there.
# However, kube-proxy sets up NAT, but assumes network basics (like reachable paths) are in place, which might not be the case in FABRIC here.
# Tests afterwards (make sure the debugging is enabled to taint the node to allow pods to be scheduled):
# Check if some pods get assigned an IP from the pod subnet (not all have it, such as most kube-system pods will have the node IP probably)
# Note: the pod subnet is not necessary to add here since this is added by the network plugin, in this example Flannel, but that network plugin 
# requires access to the service subnet before being able to do that, which was the problem here.
kubectl get pods -o wide -A
# Test if pods can reach each other:
kubectl run test-pod --rm -it --image=busybox --restart=Never -- sh
# Ping another pod with this command, such as (see result of get pods for an ip from the pod subnet CIDR):
ping 192.168.0.6
exit
# Test service routing:
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --target-port=80
# Create test pod again:
kubectl run test-pod --rm -it --image=busybox --restart=Never -- sh
# Inside it, run this command to test connection to the service, such as (or use curl or ping for example):
wget -O- nginx.default.svc.cluster.local
exit
# Should return an HTML page or something similar
# Finally, execute into a flannel pod (or other network addon) and list the ip routes, should include the service and pod subnet now, such as:
kubectl -n kube-flannel exec -it kube-flannel-ds-hzg86 -- sh
ip route


# Next, join a worker node and test the following:
# All nodes should be Ready:
kubectl get nodes -o wide
# Create a pod on the worker node, such as (this overrides the nodeSelector to use node2):
kubectl run test-on-worker \
  --rm -it \
  --image=busybox \
  --restart=Never \
  --overrides='{"spec": {"nodeSelector": {"kubernetes.io/hostname": "node2"}}}' \
  -- sh 
# Verify the status of the node, such as in k9s from the control plane node or if the above command works without infinite loading or errors, or:
kubectl get pod test-on-worker -o wide
# Now test pod-to-pod connectivity from different nodes. First view all pods:
kubectl get pods -o wide -A
# Then in the other terminal session opened by the above command for running the test-on-worker pod, run this:
ping <pod-ip-of-pod-on-different-node>
# Such as:
ping 192.168.0.13 # Pod on different node example (verify that the pod is actually on a different node with the previous command that showed all pods)
ping 10.145.2.2 # Node itself (control plane node)
exit
# Now we will test service routing on a different node. First create the services again:
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --target-port=80
# Create test pod again:
kubectl run test-on-worker \
  --rm -it \
  --image=busybox \
  --restart=Never \
  --overrides='{"spec": {"nodeSelector": {"kubernetes.io/hostname": "node2"}}}' \
  -- sh 
# Inside it, run this command to test connection to the service, such as (or use curl or ping for example):
wget -O- nginx.default.svc.cluster.local
exit
# Should return an HTML page or something similar
# Finally, execute into a flannel pod on the worker node (or other network addon) and list the ip routes, should include the service and pod subnet now, such as:
kubectl -n kube-flannel exec -it kube-flannel-ds-hzg86 -- sh
ip route

# At the end, do not forget to disable scheduling pods on the control plane node: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm#control-plane-node-isolation
kubectl taint nodes node1 node-role.kubernetes.io/control-plane=:NoSchedule
```

### Additional information beyond solution
A lot of guides said this that did not work for me (but could be useful with similar issues):
```sh
# Ensure ip forwarding is allowed, should be 1 for enabled:
sudo sysctl net.ipv4.ip_forward

# Stop kubelet and docker in SSH in the node:
sudo systemctl stop kubelet
sudo systemctl stop docker

# Disable firewall temporarily (not recommended for production, just test it and then see if it works. If it works, you need to edit the firewall settings):
systemctl stop kubelet
# Allow IP forwarding:
sudo sysctl -w net.ipv4.ip_forward=1

# Also, you can use iptables:
# Flush and reset iptables for fresh creation:
sudo bash -c 'iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X'
# Or individuall you can do "sudo iptables --flush && sudo iptables -tnat --flush" if above does nothing
# See iptables (normal and NAT related) to verify, should now be empty rules (except the forward, input and output created below possibly)
sudo iptables -L -n -v
sudo iptables -t nat -L -n -v
# Temporarily edit iptables to set default to accept if no rule matches: "If no rule matches a packet, just accept it"
sudo iptables -P FORWARD ACCEPT
sudo iptables -P INPUT ACCEPT
sudo iptables -P OUTPUT ACCEPT
# See iptables (normal and NAT related) to verify, should now see the added rules
sudo iptables -L -n -v
sudo iptables -t nat -L -n -v

# Restart kublet and docker (will restart kubernetes services and pods, which will create the iptables):
sudo systemctl start kubelet
sudo systemctl start docker
# Verify that it worked. This was generally the problem when I searched for the issue on internet for almost all.
# However, for FABRIC this did not work unfortunately.
```
This article was helpful here: https://www.baeldung.com/ops/kubernetes-error-no-route-to-host. However, it did not work in this case, meaning something else was the issue.

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