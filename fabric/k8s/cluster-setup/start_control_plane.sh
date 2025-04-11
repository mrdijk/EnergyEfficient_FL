#!/bin/bash

subnet=$1
ip=$2
interfaceDevice=$3

{

# Debugging and development tips: you can SSH into the node and run commands separately to test the behaviour without having to run the whole script for example.

echo "================================================ Starting start script for Kubernetes cluster control plane node ================================================"

# TODO: remove subnet?
echo "Subnet: ${subnet}"
echo "IP: ${ip}"
echo "Interface: ${interfaceDevice}"

# Use the cri socket created in the previous step for Docker Engine with cri-dockerd:
# https://v1-31.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#installing-runtime
# You can verify this with SSH into the node and running "cd /var/run" and then "ls" to see the socket file.
# This is important, since it may otherwise use a different CRI than desired. 
K8S_CRI_SOCKET=unix:///var/run/cri-dockerd.sock
# Subnet used for pods in the kubernetes cluster. Run in a node after SSH into it "ip a" and "ip route" to get real subnets you can use to avoid conflicts. 
# This is the same pods CIDR used in the example for Calico: https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart#create-a-single-host-kubernetes-cluster
POD_NETWORK_CIDR=192.168.0.0/16
# Do the same for the services, below is the default (see result of "kubeadm config print init-defaults")
SERVICE_NETWORK_CIDR=10.96.0.0/12



# Reset the node with kubeadm before applying to avoid potential previous installations conflicting, allowing to rerun this script without having to completely 
# recreate nodes/VMs before retrying the script.
# https://v1-31.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#tear-down
# Use specific CRI socket, see above explanation for variable used
yes | sudo kubeadm reset -f --cri-socket=$K8S_CRI_SOCKET
# This does not remove some aspects, as output by the above command, you may want to do that manually if needed, such as:
# Remove directory:
sudo rm -rf /etc/cni/net.d
# Remove iptables (with root access for all commands):
sudo bash -c 'iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X'


# TODO: add here explaining preparing the host for the network plugin: https://github.com/flannel-io/flannel?tab=readme-ov-file#deploying-flannel-manually
# Ensure bridge and ip forward are enabled and make it persistent 
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system
# Ensure the required CNI Network Plugin is installed: https://github.com/containernetworking/plugins
ARCH=$(uname -m)
  case $ARCH in
    armv7*) ARCH="arm";;
    aarch64) ARCH="arm64";;
    x86_64) ARCH="amd64";;
  esac
mkdir -p /opt/cni/bin
# Check if CNI plugins are already present
if [ ! -f /opt/cni/bin/bridge ] || [ ! -f /opt/cni/bin/host-local ]; then
  echo "CNI plugins not found — downloading and extracting..."
  curl -O -L https://github.com/containernetworking/plugins/releases/download/v1.6.2/cni-plugins-linux-$ARCH-v1.6.2.tgz
tar -C /opt/cni/bin -xzf cni-plugins-linux-$ARCH-v1.6.2.tgz
else
  echo "CNI plugins already exist — skipping download and extraction."
fi
# Make sure br_netfilter is loaded (required for Flannel)
sudo modprobe br_netfilter
# Check:
lsmod | grep br_netfilter




# TODO: additional settings here, such as ip forwarding:
# See ip forwarding setting:
# sysctl net.ipv4.ip_forward
# See firewall, should be inactive (since the slice is already isolated, it is not really required here)
# sudo ufw status verbose
# Can disable if needed with:
# sudo ufw disable
# See iptables (normal and NAT related)
# sudo iptables -L -n -v
# sudo iptables -t nat -L -n -v
# TODO: after this it worked:
# sudo sysctl -w net.ipv4.ip_forward=1
# sudo ip route add 10.96.0.0/12 dev enp7s0
# sudo iptables -P FORWARD ACCEPT
# sudo iptables -P INPUT ACCEPT
# sudo iptables -P OUTPUT ACCEPT
# kubectl delete pod -n kube-system -l k8s-app=calico-kube-controllers
# kubectl delete pod -n kube-system -l k8s-app=calico-node
# # TODO: only ip route add also did it with tigera-operator, after restarting pod:
# sudo ip route add 10.96.0.0/12 dev enp7s0  # Service CIDR
# sudo ip route add 192.168.0.0/16 dev enp7s0  # Pod CIDR used by Calico
# # TODO: pod subnet also necessary?
# kubectl delete pod -n tigera-operator -l k8s-app=tigera-operator
# # TODO: ip for pod subnet is not needed, since this causes issues.
# # TODO: try this and then retry with k8s:
# # iptables --flush
# # iptables -t nat --flush
# sudo systemctl stop kubelet
# sudo systemctl stop docker
# sudo iptables --flush
# sudo iptables -tnat --flush
# sudo systemctl start kubelet
# sudo systemctl start docker
# TODO: even after that it does not work.

# TODO: what does work to run tigera-operator:
# sudo ip route add 10.96.0.0/12 dev enp7s0
# TODO: do need to add pod subnet as well?
# kubectl delete pod -n tigera-operator -l k8s-app=tigera-operator

# ================================================ Creating configuration file ================================================
echo "================= Creating config file... =================" 
# === General: ===
# Create the file manually with the configuration.
# Customizing components: https://v1-31.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/control-plane-flags/
# Also see: https://v1-31.docs.kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta4/
# Use the above specific version with the apiVersion, this is the corresponding reference!
# If some configuration types are not provided, or provided only partially, kubeadm will use default values. So, only specify absolutely required args here.
# See the defaults to view the format with these commands for instpiration and more possible options:
# kubeadm config print init-defaults
# kubeadm config print init-defaults --component-configs KubeletConfiguration
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
  serviceSubnet: "$SERVICE_NETWORK_CIDR"
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
sudo kubeadm config validate --config kubeadm-kubelet-extraargs.yaml
# Verify the actual config file at the end of this script

# ================================================ Initialize kubernetes cluster ================================================
echo "================= Initializing cluster with Kubeadm =================" 
# Initialize the cluster with kubeadm. Kubeadm init reference: https://v1-31.docs.kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-init/
# Execute init to initialize the cluster with kubeadm
# TODO: explain using config file to add node-ip, like explained above to get correct ip for the node
# sudo kubeadm init --pod-network-cidr=${subnet} --apiserver-advertise-address=${ip} --cri-socket=unix:///var/run/cri-dockerd.sock
# sudo kubeadm init --pod-network-cidr=192.168.0.0/16 --cri-socket=$K8S_CRI_SOCKET --apiserver-advertise-address=${ip}
# Ignore specific error for ipv6 forwarding, not necessary here and will otherwise cancel operations
sudo kubeadm init --config kubeadm-kubelet-extraargs.yaml --ignore-preflight-errors=FileContent--proc-sys-net-ipv6-conf-default-forwarding
# TODO: cleanup
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
# Make sure envsubst is present:
envsubst --help
# Set variables for the environment
export FLANNEL_IFACE="$interfaceDevice"
export FLANNEL_NETWORK="$POD_NETWORK_CIDR"
# TODO: maybe this:
# ip route add $SUBNET via $PUBLIC_IP
# This replaces variables like ${FLANNEL_IFACE} with their current values from the environment, and saves the result to a new file
envsubst < kube-flannel.yaml > kube-flannel-edited.yaml
# View file, should have replaced variables
cat kube-flannel-edited.yaml
# Apply the custom kube-flannel, original can be found here: https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml
kubectl apply -f kube-flannel-edited.yaml
# TODO: do need to specify interface, but try without first
# TODO: see DirectRouting option, maybe this is good since they are on the same subnet: https://github.com/flannel-io/flannel/blob/master/Documentation/backends.md




# TODO: save this to old and commented at the bottom of this script if it works with Flannel
# Read the documentation to understand what needs to be done for kubernetes: https://docs.tigera.io/calico/latest/about/kubernetes-training/
# echo "================= Applying Calico CNI plugin =================" 
# Wait shortly to ensure initialization is complete
sleep 5
# See for a full guide: https://docs.tigera.io/calico/latest/getting-started/kubernetes/quickstart
# Use Calico with specific version for compatability with kubernetes (see: https://docs.tigera.io/calico/latest/getting-started/kubernetes/requirements)
CALICO_VERSION=v3.29.3
# Use the tigera operator (use create because due to the large size of the CRD bundle kubectl apply might exceed request limits)
# kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/tigera-operator.yaml
# Configurating specifics for Calico: https://docs.tigera.io/calico/latest/getting-started/kubernetes/self-managed-onprem/config-options
# Specifically for this custom resource file to install calico, use this reference: https://docs.tigera.io/calico/latest/reference/installation/api
# See for choosing the network option: https://docs.tigera.io/calico/latest/networking/determine-best-networking, specifically: https://docs.tigera.io/calico/latest/networking/determine-best-networking#networking-options
# This can be done with a custom resource (with correct version): https://raw.githubusercontent.com/projectcalico/calico/${CALICO_VERSION}/manifests/custom-resources.yaml
# This is the file content but then specific for this cluster in FABRIC:
cat <<EOF > calico-custom-resources.yaml
# This section includes base Calico installation configuration.
# For more information, see: https://docs.tigera.io/calico/latest/reference/installation/api#operator.tigera.io/v1.Installation
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  # Configures Calico networking: https://docs.tigera.io/calico/latest/reference/installation/api#operator.tigera.io%2fv1.CalicoNetworkSpec
  calicoNetwork:
    # Disable BGP, since FABRIC nodes do not support it by default
    bgp: Disabled
    # See: https://docs.tigera.io/calico/latest/reference/resources/ippool
    ipPools:
      - name: default-ipv4-ippool
        cidr: "$POD_NETWORK_CIDR"
        # Use VXLAN since FABRIC nodes do not support BGP by default
        encapsulation: VXLAN
        nodeSelector: all()
    # Allow IP forwarding, similar to 
    containerIPForwarding: Enabled
    # Auto detection for IPv4 of FABRIC specific nodes network
    nodeAddressAutodetectionV4:
      interface: "$interfaceDevice"
---
# This section configures the Calico API server.
# For more information, see: https://docs.tigera.io/calico/latest/reference/installation/api#operator.tigera.io/v1.APIServer
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}
EOF
# Verify created file content:
cat calico-custom-resources.yaml
# Note: if nothing changes and you do not see calico-node-x pods created, then it is likely the tigera-operator encountered errors (even though it is running, see logs).
# Create with the custom resources, TODO: explain what this does
# kubectl create -f calico-custom-resources.yaml
# TODO: left off here, this does nothing yet with applying

# TODO: below for calico can probably be removed
# # Download calico manifest 
# # Currently using version 3.29 for compatability with Kubernetes
# curl https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/calico.yaml -O
# # Apply manifest
# kubectl apply -f calico.yaml
# Or:
# kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.3/manifests/calico.yaml
# TODO: add here from guide: 
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
# Verify Node internal IP afterwards. This will likely still show status NotReady, since it takes a while before Calico to apply.
echo "Verify node internal IP, should now be the custom created network with IPv4/passed ip address to this script"
kubectl get nodes -o wide
kubectl get pods --all-namespaces

# With problems, verify the kubeconfig, such as the server endpoint used for the default api address:
# cat $HOME/.kube/config
# Get server from kubeconfig
echo "Api server endpoint from kubelet:"
cat $HOME/.kube/config | grep server
# Display cluster information
kubectl cluster-info

# TODO: print nodes not necessary I think, since right after apply of calico it will be NotReady anyway.
# # Print nodes
# kubectl get nodes\\

# TODO: maybe do something with cluster dns, depending on DYNAMOS local setup, such as cluster.local?

echo "Start control plane node complete."

}  2>&1 | tee -a start_control_plane.log
