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
# This is important, since it may otherwise use a different CRI than desired. 
K8S_CRI_SOCKET=unix:///var/run/cri-dockerd.sock
# Subnet used for pods in the kubernetes cluster. Run in a node after SSH into it "ip a" and "ip route" to get real subnets you can use to avoid conflicts. 
# This is the same CIDR used in the example for Calico: https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart#create-a-single-host-kubernetes-cluster
POD_NETWORK_CIDR=192.168.0.0/16
# TODO: use specific pod network cidr, add explanation here, such as not taken by anything, SSH into a node and run:


# TODO: add explanation why this
# https://v1-31.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#tear-down
# Use specific CRI socket, see above explanation for variable used
yes | sudo kubeadm reset -f --cri-socket=$K8S_CRI_SOCKET
# This does not remove some aspects, as output by the above command, you may want to do that manually if needed, such as:
# # Remove directory:
# sudo rm -rf /etc/cni/net.d
# # Remove iptables (with root access for all commands):
# sudo bash -c 'iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X'


# ================================================ Creating configuration file ================================================
echo "================= Creating config file... =================" 
# === General: ===
# Create the file manually with the configuration.
# Customizing components: https://v1-31.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/control-plane-flags/
# Also see: https://v1-31.docs.kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta4/
# Use the above specific version with the apiVersion, this is the corresponding reference!
# If some configuration types are not provided, or provided only partially, kubeadm will use default values. So, only specify absolutely required args here.
#
# === Cluster configuration specific: ===
# Pod subnet is the --pod-network-cidr option, used for internal pod networking, see explanation above where the variable is created.
# Networking: https://v1-31.docs.kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta4/#kubeadm-k8s-io-v1beta4-Networking
# The api-server advertise address is IP address on which to advertise the apiserver to members of the cluster (the --apiserver-advertise-address option in kubeadm init), 
# see for all arguments: https://v1-31.docs.kubernetes.io/docs/reference/command-line-tools-reference/kube-apiserver/
# The rest can be left on default.
#
# === Init configuration (for node ip and cri socket) specific: ===
# Use specific CRI socket, see above explanation for variable used for CRI socket.
# Also, add localAPIEndpoint to ensure kubectl uses the correct api-server address without detecting IPv6 or other addresses automatically, which caused problems before.
#
# Also, set INTERNAL-IP to correct IP for the node of the custom network added over IPv4. By default it would use a different interface, since that is the main one
# on the FABRIC node, such as with the IP: 10.30.6.111. But we want the IP from the network we created since the nodes can communicate with each other in this network:
# See https://v1-31.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/kubelet-integration/#configure-kubelets-using-kubeadm
# And specifically: https://v1-31.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/kubelet-integration/#workflow-when-using-kubeadm-init
# See reference for possible args (without -- part), specifically node-ip: https://v1-31.docs.kubernetes.io/docs/reference/command-line-tools-reference/kubelet/
echo "Creating kubeadm config file..."
cat <<EOF > kubeadm-kubelet-extraargs.yaml
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
networking:
  podSubnet: "$POD_NETWORK_CIDR"
apiServer:
  extraArgs:
  - name: "advertise-address"
    value: "$ip"
---
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: "$ip"
nodeRegistration:
  criSocket: "$K8S_CRI_SOCKET"
  kubeletExtraArgs:
    - name: node-ip
      value: "$ip"
EOF
# Verify created file content:
cat kubeadm-kubelet-extraargs.yaml
echo "Validating config file with kubeadm config validate..."
# Verify with kubeadm: https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-config/#cmd-config-validate
kubeadm config validate --config kubeadm-kubelet-extraargs.yaml
# See the defaults to view the format with these commands:
# kubeadm config print init-defaults
# kubeadm config print init-defaults --component-configs KubeletConfiguration
# TODO: how to view configuration afterwards.


# ================================================ Initialize kubernetes cluster ================================================
echo "================= Initializing cluster with Kubeadm =================" 
# Initialize the cluster with kubeadm. Kubeadm init reference: https://v1-31.docs.kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/
# Execute init to initialize the cluster with kubeadm
# TODO: explain using config file to add node-ip, like explained above to get correct ip for the node
# sudo kubeadm init --pod-network-cidr=${subnet} --apiserver-advertise-address=${ip} --cri-socket=unix:///var/run/cri-dockerd.sock
# sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --cri-socket=$K8S_CRI_SOCKET --apiserver-advertise-address=${ip}
# Ignore specific error for ipv6 forwarding, not necessary here and will otherwise cancel operations
sudo kubeadm init --config kubeadm-kubelet-extraargs.yaml --ignore-preflight-errors=FileContent--proc-sys-net-ipv6-conf-default-forwarding
# 
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


# TODO: maybe:https://v1-31.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/control-plane-flags/#customizing-kube-proxy


# ================================================ Calico for Networking ================================================
# echo "================= Applying Calico CNI plugin =================" 
# # Wait shortly to ensure initialization is complete
# sleep 10
# # Download calico manifest with specific version for compatability (see: https://docs.tigera.io/calico/latest/getting-started/kubernetes/requirements)
# # Currently using version 3.29 for compatability with Kubernetes
curl https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/calico.yaml -O
# Apply manifest
kubectl apply -f calico.yaml
# TODO: add here from guide: https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart
# TODOs:
# Use specific interface and set ips, just like with kube-proxy specific

# ================================================ Verification ================================================
# TODO: verify cgroup driver for kubeadm after init in next script?
# === Verify Config used by kubeadm ===
echo "Verify config used by kubeadm correctly contains the custom created config variables, and applied default values correctly"
# Old command, did the same: kubectl get configmap kubeadm-config -n kube-system -o yaml
kubectl -n kube-system get cm kubeadm-config -o yaml
# === Verify Node IP ===
# After creating the file, verify the config file changes worked
# It explains it creates a file /var/lib/kubelet/kubeadm-flags.env, which we can verify the contents with this command:
echo "Verify kubeadm flags, should now include --node-ip" 
sudo cat /var/lib/kubelet/kubeadm-flags.env
# Verify Node internal IP afterwards
echo "Verify node internal IP, should now be the custom created network with IPv4/passed ip address to this script"
kubectl get nodes -o wide

# With problems, verify the kubeconfig, such as the server endpoint used for the default api address:
# cat $HOME/.kube/config
# Get server from kubeconfig
echo "Api server endpoint from kubelet:"
cat $HOME/.kube/config | grep server

# TODO: print nodes not necessary I think, since right after apply of calico it will be NotReady anyway.
# # Print nodes
# kubectl get nodes\\

# TODO: maybe do something with cluster dns, depending on DYNAMOS local setup, such as cluster.local?

echo "Start control plane node complete."

}  2>&1 | tee -a start_control_plane.log
