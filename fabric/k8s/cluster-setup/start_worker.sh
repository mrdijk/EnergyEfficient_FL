#!/bin/bash

currentNodeIP=$1
interfaceDevice=$2
controlPlaneIP=$3

{

# Debugging and development tips: you can SSH into the node and run commands separately to test the behaviour without having to run the whole script for example.

echo "================================================ Starting start script for Kubernetes cluster worker node ================================================"
echo "Current Node IP: ${currentNodeIP}"
echo "Interface: ${interfaceDevice}"
echo "Control Plane Node IP: ${controlPlaneIP}"

# Same variables as start_controle_plane.sh
K8S_CRI_SOCKET=unix:///var/run/cri-dockerd.sock
SERVICE_NETWORK_CIDR=10.96.0.0/12
# Use bind port set in start_control_plane.sh
API_BIND_PORT=6443
# Specific join variables
# TODO: change to input probably:
JOIN_TOKEN="wh8zbn.moko0xq6pagjvld3"
CA_CERT_HASH="sha256:d6e5eb3954c537cd907d868fb154de6583127fe8ae0e08e5f0bd4f8e441e6290"

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
# Note: if you added the node before, you need to delete it from the control plane node, such as:
# kubectl delete node node2

# TODO: add things here from start control plane, such as the config, but then for JoinConfiguration instead of InitConfiguration.
# TODO: also maybe set: JoinConfiguration.controlPlane.localAPIEndpoint

# TODO: add here explaining preparing the host for the network plugin: https://github.com/flannel-io/flannel?tab=readme-ov-file#deploying-flannel-manually
# Ensure bridge and ip forward are enabled and make it persistent 
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv6.conf.default.forwarding = 1
EOF
# TODO: do the same for start_control_plane with the defaults:
# TODO: this might be something as well, as it may need to be 1:
# sysctl net.ipv4.conf.all.rp_filter
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
# TODO: add fixes from previous here as well, such as:
# If it says something like File Exists, the route already exists and this can be skipped.
echo "SERVICE_NETWORK_CIDR is $SERVICE_NETWORK_CIDR"
echo "interfaceDevice is $interfaceDevice"
if [[ -n "$SERVICE_NETWORK_CIDR" && -n "$interfaceDevice" ]]; then
  sudo ip route add "$SERVICE_NETWORK_CIDR" dev "$interfaceDevice"
else
  echo "ERROR: SERVICE_NETWORK_CIDR or interfaceDevice is unset."
fi
# List ip routes
sudo ip route

# TODO: add custom join setup here.


# ================================================ Creating configuration file ================================================
echo "================= Creating config file... =================" 
# See start_control_plane.sh for full explanation on creating kubeadm config files. Specifically for this script:
# Also see the full API reference: https://v1-31.docs.kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta4/
# This adds similar settings to the control plane, such as adding the specific node-ip of this node and the CRI Socket. 
# Discovery is rerquired for the join command, which has token and the hash for a cert.
# The rest is left to default values, since kubernetes adds them as configured in the control plane and detects others automatically
echo "Creating kubeadm config file..."
cat <<EOF > kubeadm-kubelet-extraargs.yaml
apiVersion: kubeadm.k8s.io/v1beta4
# https://v1-31.docs.kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta4/#kubeadm-k8s-io-v1beta4-JoinConfiguration
kind: JoinConfiguration
discovery:
  # Setting bootstrap token automatically fills the other values, so only this needs to be set: https://v1-31.docs.kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta4/#kubeadm-k8s-io-v1beta4-Discovery 
  bootstrapToken:
    token: "$JOIN_TOKEN"
    apiServerEndpoint: "$controlPlaneIP:$API_BIND_PORT"
    caCertHashes:
      - "$CA_CERT_HASH"
nodeRegistration:
  criSocket: "$K8S_CRI_SOCKET"
  kubeletExtraArgs:
    - name: node-ip
      value: "$currentNodeIP"
EOF
# TODO: rename file to better one
# Verify created file content:
cat kubeadm-kubelet-extraargs.yaml
echo "Validating config file with kubeadm config validate..."
# Verify with kubeadm: https://kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-config/#cmd-config-validate
sudo kubeadm config validate --config kubeadm-kubelet-extraargs.yaml
# Verify the actual config file at the end of this script

# Join the cluster: https://v1-31.docs.kubernetes.io/docs/reference/setup-tools/kubeadm/kubeadm-join/
# TODO: change to variable now for token and hash or entire command with sudo:
sudo kubeadm join 10.145.2.2:6443 --config kubeadm-kubelet-extraargs.yaml
# TODO: can run on control plane node: kubeadm token create --print-join-command

echo "Start worker node complete."

}  2>&1 | tee -a start_worker.log
