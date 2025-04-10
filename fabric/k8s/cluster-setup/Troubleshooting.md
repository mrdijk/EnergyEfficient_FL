# Troubleshooting
This file describes any possible problems that occurred during our setup of the Kubernetes cluster.

Note: do not forget to upload the kubespray changes to the remote host controle plane (in this case node1)! Otherwise, the changes will not apply. For example, reupload the whole kubespray file with several files changed, and only a file when only one file changed, etc.

See for more information: https://kubernetes.io/docs/tasks/debug/


## Calico-kube-controllers not working/kube-proxy problems
Problem:
```sh
calico-node 2025-04-10 06:23:30.692 [INFO][9] startup/startup.go 459: Hit error connecting to datastore - retry error=Get "https://10.96.0.1:443/api/v1/nodes/foo": dial tcp 10.96.0.1:443: connect: network is unreachable
```
This was fixed by manually running on the node in SSH:
```sh
sudo sysctl -w net.ipv4.ip_forward=1
sudo ip route add 10.96.0.0/12 dev enp7s0
sudo iptables -P FORWARD ACCEPT
kubectl delete pod -n kube-system -l k8s-app=calico-kube-controllers
kubectl delete pod -n calico-system -l k8s-app=calico-node
```
TODO: what exactly did it?

Second problem after that:
```sh
2025-04-10 06:49:10.689 [ERROR][1] kube-controllers/client.go 320: Error getting cluster information config ClusterInformation="default" error=Get "https://10.96.0.1:443/apis/crd.projectcalico.org/v1/clust ││ erinformations/default": dial tcp 10.96.0.1:443: connect: no route to host
```

A lot of guides said:
```sh
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

What we did to fix it on FABRIC:
```sh
# Ensure the ip routes for the pod subnet and service subnet in kubernetes are added:
sudo ip route add 10.96.0.0/12 dev enp7s0  # Service CIDR
sudo ip route add 192.168.0.0/16 dev enp7s0  # Pod CIDR used by Calico
# Ensure it goes to the correct interface, should print the above specified one, such as:
ubuntu@Node1:~$ ip route get 10.96.0.1
# TODO: that did not do anything now.

# SSH into the node and execute something from a calico pod (replace with actual pod name), such as:
kubectl exec -it -n calico-system calico-node-6c62k -- bash
```
TODO: finish this with eventual solution.


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