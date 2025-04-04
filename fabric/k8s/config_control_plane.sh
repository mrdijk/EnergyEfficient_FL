#!/bin/bash

{

echo "==== Starting post-install script for Kubespray cluster ===="

# Set up kubeconfig for the current user to use kubectl
echo "Setting up kubeconfig..." 
# Creates the .kube folder where kubectl looks for config by default
mkdir -p $HOME/.kube
# Copies the admin kubeconfig to your user folder (use -f to force overwrite potential existing files)
sudo cp -f /etc/kubernetes/admin.conf $HOME/.kube/config
# Gives your user permission to read it (this is a very important step, otherwise it cannot be read!)
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Wait briefly to ensure Kubernetes components have time to stabilize
sleep 10

# Display the status of all nodes
echo "Checking cluster nodes..."
kubectl get nodes

# Display the status of all system-level pods
echo "Checking system pods..."
kubectl get pods -n kube-system

echo "Kubespray control plane post-setup complete."

# Everything inside this block (stdout and stderr) will be piped and logged
# The line below does the following:
# - 2>&1 : Redirects stderr (2) to stdout (1), combining output and errors
# - | tee -a : Pipes combined output to both the terminal and the log file
# - config_control_plane.log : Appends all logs to this file
} 2>&1 | tee -a config_control_plane.log
