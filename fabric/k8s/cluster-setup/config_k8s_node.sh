#!/bin/bash

{

echo "==== Starting config script for Kubernetes cluster node ===="

sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get update && sudo apt-get install -y docker.io apt-transport-https curl python3 python3-venv python3-pip ca-certificates gpg

# Remove references to old google repository from kubernetes (used in old config for Kubernetes in FABRIC, this avoids interference)
sudo rm /etc/apt/sources.list.d/docker.list /etc/apt/sources.list.d/kubernetes.list

# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

sudo apt-get update -y
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl

sudo swapoff -a

sudo sh -c "echo {                                                  >  /etc/docker/daemon.json"
sudo sh -c 'echo \"exec-opts\": [\"native.cgroupdriver=systemd\"]  >>  /etc/docker/daemon.json'
sudo sh -c "echo }                                                 >>  /etc/docker/daemon.json"

sudo systemctl enable docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# Everything inside this block (stdout and stderr) will be piped and logged
# The line below does the following:
# - 2>&1 : Redirects stderr (2) to stdout (1), combining output and errors
# - | tee -a : Pipes combined output to both the terminal and the log file
# - config_k8s_node.log : Appends all logs to this file
} 2>&1 | tee -a config_k8s_node.log
