#!/bin/bash

subnet=$1
ip=$2

{

# Debugging and development tips: you can SSH into the node and run commands separately to test the behaviour without having to run the whole script for example.

echo "================================================ Starting start script for Kubernetes cluster control plane node ================================================"

echo "Subnet: ${subnet}"
echo "IP: ${ip}"

# Use the cri socket created in the previous step for Docker Engine with cri-dockerd:
# https://v1-31.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-runtime
# You can verify this with SSH into the node and running "cd /var/run" and then "ls" to see the socket file.
# This is important, since it may otherwise use a different CRI than desired
K8S_CRI_SOCKET=unix:///var/run/cri-dockerd.sock

# TODO: add explanation why this
# https://v1-31.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#tear-down
# Use specific CRI socket, see above explanation for variable used
yes | sudo kubeadm reset -f --cri-socket=$K8S_CRI_SOCKET
# This does not remove some aspects, as output by the above command, you may want to do that manually if needed, such as:
# Remove directory:
# sudo rm -rf /etc/cni/net.d
# Remove iptables (with root access for all commands):
# sudo bash -c 'iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X'

# ================================================ Initialize kubernetes cluster ================================================
echo "================= Initializing cluster with Kubeadm =================" 
# Initialize the cluster, see reference: https://v1-31.docs.kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/
# TODO: explain using ip, control-plane ip for 
# sudo kubeadm init --pod-network-cidr=${subnet} --apiserver-advertise-address=${ip} --cri-socket=unix:///var/run/cri-dockerd.sock
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --cri-socket=$K8S_CRI_SOCKET --apiserver-advertise-address=${ip}
# TODO: use specific pod network cidr, add explanation here, such as not taken by anything, SSH into a node and run:
# "ip a" and "ip route" to get real subnets you can use to avoid conflicts. This is the same CIDR used in the example for Calico: 
# https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart#create-a-single-host-kubernetes-cluster
# TODO: with join, you need the token and hash from this command output: kubeadm token create --print-join-command
# TODO: maybe do need to use subnet like in kubernetes simple example, but then with calico specific settings.
# TODO: use specific ip like here with this command for worker as well, like here with control-plane so that it does it correctly, verify in kube-proxy pod logs for node.


# === KUBECONFIG Setup ===
# Set up kubeconfig for the current user to use kubectl
echo "Setting up kubeconfig..." 
# Creates the .kube folder where kubectl looks for config by default
mkdir -p $HOME/.kube
# Copies the admin kubeconfig to your user folder (use -f to force overwrite potential existing files)
sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
# Gives your user permission to read it (this is a very important step, otherwise it cannot be read!)
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# === Validate kubeconfig ===
if ! kubectl version >/dev/null 2>&1; then
  echo "kubectl cannot connect to the cluster. Check admin.conf or cluster status."
  exit 1
fi
echo "kubeconfig is valid."

# TODO: set INTERNAL-IP to correct IP for the node of the custom network added over IPv4. By default it would use a different interface, since that is the main one
# on the FABRIC node, such as with the IP: 10.30.6.111. But we want the IP from the network we created since the nodes can communicate with each other in this network:
# See https://v1-31.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/kubelet-integration/#configure-kubelets-using-kubeadm
# And specifically: https://v1-31.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/kubelet-integration/#workflow-when-using-kubeadm-init
# $ip

# See reference, specifically node-ip: https://v1-31.docs.kubernetes.io/docs/reference/command-line-tools-reference/kubelet/
# Verify node, should use correct IP now:
kubectl get nodes -o wide
# TODO: maybe:https://v1-31.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/control-plane-flags/#customizing-kube-proxy


# ================================================ Calico for Networking ================================================
# echo "================= Applying Calico CNI plugin =================" 
# # Wait shortly to ensure initialization is complete
# sleep 10
# # Download calico manifest with specific version for compatability (see: https://docs.tigera.io/calico/latest/getting-started/kubernetes/requirements)
# # Currently using version 3.29 for compatability with Kubernetes
# curl https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/calico.yaml -O
# # Apply manifest
# kubectl apply -f calico.yaml
# TODO: add here from guide: https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart
# TODOs:
# Use specific interface and set ips, just like with kube-proxy specific

# ================================================ Verification ================================================
# TODO: verify cgroup driver for kubeadm after init in next script?

# TODO: print nodes not necessary I think, since right after apply of calico it will be NotReady anyway.
# # Print nodes
# kubectl get nodes

echo "Start control plane node complete."

}  2>&1 | tee -a start_control_plane.log
