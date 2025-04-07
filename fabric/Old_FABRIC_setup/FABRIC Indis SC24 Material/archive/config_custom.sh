#!/bin/bash

# Update and install Docker
sudo apt update
sudo apt install -y docker.io apt-transport-https curl

# Configure Docker to use systemd as the cgroup driver
sudo mkdir -p /etc/docker
cat <<EOF | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"]
}
EOF

sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# Add Kubernetes APT repository
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
sudo apt-add-repository "deb https://apt.kubernetes.io/ kubernetes-xenial main"

# Update and install kubelet, kubeadm, and kubectl
sudo apt update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

# Disable swap as Kubernetes does not support swap
sudo swapoff -a

# Initialize single-node Kubernetes control plane
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Configure kubectl for the local user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Apply Flannel network plugin
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

# Allow scheduling on the control plane node
kubectl taint nodes --all node-role.kubernetes.io/control-plane-

echo "Kubernetes single-node setup is complete. You can check the node status with 'kubectl get nodes'."