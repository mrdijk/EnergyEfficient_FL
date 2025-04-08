#!/bin/bash

subnet=$1
ip=$2

{

echo ${subnet}
echo ${ip}

yes | sudo kubeadm reset

# === Initialize kubernetes cluster  ===
echo "Initializing with Kubeadm..." 
sudo kubeadm init --pod-network-cidr=${subnet} --apiserver-advertise-address=${ip}

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

# === Calico for Networking ===
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
# Print nodes
kubectl get nodes

}  2>&1 | tee -a start_control_plane.log
