# Troubleshooting
This file describes any possible problems that occurred during our setup of the Kubernetes cluster.

Note: do not forget to upload the kubespray changes to the remote host controle plane (in this case node1)! Otherwise, the changes will not apply. For example, reupload the whole kubespray file with several files changed, and only a file when only one file changed, etc.

See for more information: https://kubernetes.io/docs/tasks/debug/


## Network connectivity issue with networking plugin for Kubernetes
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
However, afterwards a new issue arose:
```sh
2025-04-10 06:49:10.689 [ERROR][1] kube-controllers/client.go 320: Error getting cluster information config ClusterInformation="default" error=Get "https://10.96.0.1:443/apis/crd.projectcalico.org/v1/clust ││ erinformations/default": dial tcp 10.96.0.1:443: connect: no route to host
```

The next sections will explain how the issue was fixed and which steps were taken to fix the issue.

First, some additional debugging tips:
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
```

At first, we used Calico as the network plugin, but after more than a week of debugging and trying to understand and fix issues in several different ways without results, the decision was made to move to another network plugin for Kubernetes to try and see if it works with a different tool. Also, this had to goal to possibly understand the issue better since this would have a slightly different setup in our environment.

After some research, it was found that Flannel was one of the first supported network plugins for Kubernetes and is generally the most simple and lightweight one, which made it a suitable choice for debugging purposes without much custom options, etc., that could possibly interfere and cause more issues.

Initially, the first issue was the same with "dial tcp 10.96.0.1:443: connect: network is unreachable". However, we knew how to fix this and did it with the same fix below:
```sh
# Eventual fix:
# Add the route for the Kubernetes service subnet, otherwise, it cannot reach that:
sudo ip route add 10.96.0.0/12 dev enp7s0
# Additional steps were added in the start_control_plane.sh, such as enabling ip forwarding, etc.:
# Preparing the host for the network plugin: https://github.com/flannel-io/flannel?tab=readme-ov-file#deploying-flannel-manually
# Ensure bridge and ip forward are enabled and make it persistent 
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system
# And:
# Make sure br_netfilter is loaded (required for Flannel)
sudo modprobe br_netfilter
# Check:
lsmod | grep br_netfilter
```
With Calico this resulted a next issue (the second issue listed above: "dial tcp 10.96.0.1:443: connect: no route to host"). However, with Flannel, after logical reasoning with the specific configuration settings (see kube-flannel.yml), it worked perfectly without problems and the tests all worked (see below full tests explanation). See section after this one for explanation on the difference with Calico and the result of testing again.

The main fix here was adding a route for the service subnet of Kubernetes to the node ip routes. This fix with adding the service subnet to the node essentially says: Please send traffic to that subnet out through enp7s0 directly, and trust the network or NAT/iptables to handle it from there. And the iptables are correctly created with kube-proxy, which is why it works from there. However, kube-proxy sets up NAT, but assumes network basics (like reachable paths) are in place, which might not be the case in FABRIC here. 

Note: the pod subnet is not necessary to add here since this is added by the network plugin, in this example Flannel, but that network plugin requires access to the service subnet before being able to do that, which was the problem here.

Something that was also important was the hostNetwork option set to true, since this says: don’t give this pod an isolated virtual network interface via the CNI plugin. Instead, run it directly on the host's network stack so the pod uses the node's actual network interfaces:
- It bypasses the CNI plugin entirely for its own networking
- It can access: The node’s routes, The cluster DNS (if resolvable by the node), The Kubernetes API via 10.96.0.1 if the node has that route
The Flannel pod can access the Kubernetes API server directly using the node’s routing table now. It doesn’t depend on a CNI plugin being functional before it starts — because it's the thing setting up the CNI. This lets it bootstrap itself cleanly, it's a bootstrap-safe design: Flannel configures the network before CNI is needed by any other pods. This is likely why with the FABRIC specific setup it works after adding the ip route.
Also, when setting the Flannel hostNetwork to false, it caused a similar issue with Calico, with Flannel in infinite Pending and coredns with error similar to Calico:
```sh
[ERROR] plugin/kubernetes: pkg/mod/k8s.io/client-go@v0.29.3/tools/cache/reflector.go:229: Failed to watch *v1.Namespace: failed to list *v1.Namespace: Get "https://10.96.0.1:443/api/v1/namespaces?limit=500 ││ &resourceVersion=0": dial tcp 10.96.0.1:443: connect: no route to host 
```

However, with Calico, while the initial problem (dial tcp 10.96.0.1:443: connect: network is unreachable) was fixed also with the ip route add, it created the second issue (dial tcp 10.96.0.1:443: connect: no route to host). While Calico did have hostNetwork set to true, it might be something else in the Calico setup that caused the problem, see below section for possibly more explanation. 

Tests to verify that it worked (besides seeing all the pods of the network plugin and coredns running in k9s or with the command to display them):
```sh
# Tests afterwards (make sure the debugging is enabled to taint the node to allow pods to be scheduled):
# Check if some pods get assigned an IP from the pod subnet (not all have it, such as most kube-system pods will have the node IP probably)
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
exit
# Cleanup:
kubectl delete svc nginx
kubectl delete deployment nginx


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
exit
# Cleanup:
kubectl delete svc nginx
kubectl delete deployment nginx


# At the end, do not forget to disable scheduling pods on the control plane node: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm#control-plane-node-isolation
kubectl taint nodes node1 node-role.kubernetes.io/control-plane=:NoSchedule
```

### Calico specific issues
After trying again with the exact same steps used for Flannel, but switching back to Calico, the same issue occurred again: dial tcp 10.96.0.1:443: connect: no route to host. Uninstalling Calico and reapplying Flannel immediately fixed the issue (without having to recreate the slice and reset the kubernetes cluster, just "kubectl apply/delete -f .." commands). This confirms the issue was specific to Calico or its configuration likely in combination to FABRIC setup specifically. This was just a test, it could be a better option to reset the kubernetes cluster with Kubeadm (and potentially even recreate the slice) for a fresh start, but here it was just a test if it would immediately work with Flannel. So, this was definitely something specific to Calico and possibly its configuration and setup.

While additional fixes for Calico may fix the issue — such as tweaking the kube-proxy configuration (https://v1-31.docs.kubernetes.io/docs/reference/config-api/kube-proxy-config.v1alpha1/) or adding more FABRIC-specific routing, etc. — these were not fully explored due to time constraints, and an already large time spend on this (more than a week).

Importantly, we do not require network policies, which is a key feature of Calico. Therefore, Flannel is a more lightweight and suitable solution for our setup on FABRIC. Flannel’s simplicity makes it more reliable in this custom environment, without the need for additional network policies. Therefore, we concluded that sticking with Flannel provides a stable and functional setup for our needs.



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