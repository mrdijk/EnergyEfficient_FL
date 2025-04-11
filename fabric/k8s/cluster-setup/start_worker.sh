#!/bin/bash

currentNodeIP=$1
interfaceDevice=$2
controlPlaneIP=$3
joinToken=$4
caCertHash=$5

{

# Debugging and development tips: you can SSH into the node and run commands separately to test the behaviour without having to run the whole script for example.

echo "================================================ Starting start script for Kubernetes cluster worker node ================================================"
echo "Current Node IP: ${currentNodeIP}"
echo "Interface: ${interfaceDevice}"
echo "Control Plane Node IP: ${controlPlaneIP}"
echo "Join token: ${joinToken}"
echo "Ca Cert HASH: ${caCertHash}"

# ================================================ Set variables ================================================
echo "================= Setting variables... =================" 
# Same variables as start_controle_plane.sh
K8S_CRI_SOCKET=unix:///var/run/cri-dockerd.sock
SERVICE_NETWORK_CIDR=10.96.0.0/12
# Use bind port set in start_control_plane.sh
API_BIND_PORT=6443

# ================================================ Reset Kubeadm to avoid interference of previous setups ================================================
echo "================= Resetting Kubeadm... =================" 
# See start_control_plane.sh for explanation on why and how this is done specifically
yes | sudo kubeadm reset -f --cri-socket=$K8S_CRI_SOCKET
sudo rm -rf /etc/cni/net.d
sudo bash -c 'iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X'
# Note: if you added the node before, you need to delete it from the control plane node, such as:
# kubectl delete node node2
# You may need additional steps, such as removing some pods in k9s or see: https://v1-31.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/create-cluster-kubeadm/#remove-the-node


# ================================================ Prepare Networking plugin (exactly the same as start_control_plane.sh) ================================================
echo "================= Preparing settings for networking plugin... =================" 
# Prepare the host for the network plugin: https://github.com/flannel-io/flannel?tab=readme-ov-file#deploying-flannel-manually
# Ensure bridge and ip forward are enabled and make it persistent 
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv6.conf.default.forwarding = 1
EOF
# Apply changes to make it persistent
sudo sysctl --system
# === CNI Plugins ===
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
# === FABRIC Network Issue fix ===
# Fix for issue with network connectivity in FABRIC: add the ip route manually for the kubernetes service subnet (see Troubleshooting.md 
# in this folder for more explanation). If it says something like File Exists, the route already exists and this can be skipped.
echo "SERVICE_NETWORK_CIDR is $SERVICE_NETWORK_CIDR"
echo "interfaceDevice is $interfaceDevice"
if [[ -n "$SERVICE_NETWORK_CIDR" && -n "$interfaceDevice" ]]; then
  sudo ip route add "$SERVICE_NETWORK_CIDR" dev "$interfaceDevice"
else
  echo "ERROR: SERVICE_NETWORK_CIDR or interfaceDevice is unset."
fi
# List ip routes to verify
sudo ip route


# ================================================ Creating configuration file for Kubeadm ================================================
echo "================= Creating config file for Kubeadm... =================" 
# See start_control_plane.sh for full explanation on creating kubeadm config files. Specifically for this script:
# Also see the full API reference: https://v1-31.docs.kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta4/
# This adds similar settings to the control plane, such as adding the specific node-ip of this node and the CRI Socket. 
# Discovery is rerquired for the join command, which has token and the hash for a cert.
# The rest is left to default values, since kubernetes adds them as configured in the control plane and detects others automatically
echo "Creating kubeadm config file..."
cat <<EOF > kubeadm-custom-init-config.yaml
apiVersion: kubeadm.k8s.io/v1beta4
# https://v1-31.docs.kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta4/#kubeadm-k8s-io-v1beta4-JoinConfiguration
kind: JoinConfiguration
discovery:
  # Setting bootstrap token automatically fills the other values, so only this needs to be set: https://v1-31.docs.kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta4/#kubeadm-k8s-io-v1beta4-Discovery 
  bootstrapToken:
    token: "$joinToken"
    apiServerEndpoint: "$controlPlaneIP:$API_BIND_PORT"
    caCertHashes:
      - "$caCertHash"
nodeRegistration:
  criSocket: "$K8S_CRI_SOCKET"
  kubeletExtraArgs:
    - name: node-ip
      value: "$currentNodeIP"
EOF
# Verify created file content:
cat kubeadm-custom-init-config.yaml
echo "Validating config file with kubeadm config validate..."
# Verify with kubeadm: https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-config/#cmd-config-validate
sudo kubeadm config validate --config kubeadm-custom-init-config.yaml
# Verify the actual config file at the end of this script

# ================================================ Join kubernetes cluster ================================================
echo "================= Joining node to cluster with Kubeadm =================" 
# Join the cluster: https://v1-31.docs.kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-join/
sudo kubeadm join 10.145.2.2:6443 --config kubeadm-custom-init-config.yaml

# ================================================ Verification ================================================
# === Verify Cgroup driver ===
echo "Verify cgroup driver, should be systemd"
sudo cat /var/lib/kubelet/config.yaml | grep cgroup
# More validation is not necessary, that can be done from the control plane node.

echo "Start worker node complete."

# Everything inside this block (stdout and stderr) will be piped and logged
# The line below does the following:
# - 2>&1 : Redirects stderr (2) to stdout (1), combining output and errors
# - | tee -a : Pipes combined output to both the terminal and the log file
# - start_worker.log : Appends all logs to this file
}  2>&1 | tee -a start_worker.log
