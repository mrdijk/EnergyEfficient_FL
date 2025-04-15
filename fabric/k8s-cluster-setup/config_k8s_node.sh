#!/bin/bash

{

# Debugging and development tips: you can SSH into the node and run commands separately to test the behaviour without having to run the whole script for example.

# Note: used Kubernetes version v1.31 for compatability, one version before the latest version
# See: https://v1-31.docs.kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
KUBERNETES_VERSION=v1.31

echo "================================================ Starting config script for Kubernetes cluster node ================================================"

# ================================================ Prepare apt package manager ================================================
echo "Preparing apt package manager (silently, only showing errors)..."
# Update the apt package index and install packages needed to use the Kubernetes apt repository
# -qq suppresses all output except errors to avoid much outputs in the logs for clarity. -y prompts yes for any inputs
sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq -y
# apt-transport-https may be a dummy package; if so, you can skip that package
sudo DEBIAN_FRONTEND=noninteractive apt-get install -qq -y apt-transport-https ca-certificates curl gpg

# ================================================ Install and Setup Docker as Container Runtime ================================================
echo "================= Installing and Setting up Docker for Container Runtime ================="
# Setup Container Runtime with Docker: https://v1-31.docs.kubernetes.io/docs/setup/production-environment/container-runtimes/#docker

# ==== Docker Engine ====
echo "==== Installing Docker Engine ===="
# First, use the ubuntu installation here for the Docker Engine: https://docs.docker.com/engine/install/ubuntu/
# Uninstall conflicting packages:
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

# Install Docker Engine: https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
# Add Docker's official GPG key:
# -qq suppresses all output except errors to avoid much outputs in the logs for clarity
sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq -y
sudo DEBIAN_FRONTEND=noninteractive apt-get install ca-certificates curl -qq
sudo DEBIAN_FRONTEND=noninteractive install -m 0755 -d /etc/apt/keyrings -qq
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
# -qq suppresses all output except errors to avoid much outputs in the logs for clarity
sudo apt-get update -qq -y
# Here I selected a specific version for compatability, which resulted in the below commands from the above guide. 
# They provide a command to list available versions, such as with SSH on the node after the above commands have been run.
# Install the specific version (added noninteractive and -y to use for specific mode here to avoid problems with prompts in the automatic script):
DOCKER_VERSION_STRING="5:28.0.4-1~ubuntu.24.04~noble"
sudo DEBIAN_FRONTEND=noninteractive apt-get install -qq -y docker-ce=$DOCKER_VERSION_STRING docker-ce-cli=$DOCKER_VERSION_STRING containerd.io docker-buildx-plugin docker-compose-plugin

# Set systemd driver explicitely for docker, see: https://docs.docker.com/engine/daemon/proxy/#daemon-configuration
# This option is used specifically: native.cgroupdriver: https://docs.docker.com/reference/cli/dockerd/#configure-cgroup-driver
# Also this explained it: https://stackoverflow.com/questions/43794169/docker-change-cgroup-driver-to-systemd
sudo sh -c "echo {                                                  >  /etc/docker/daemon.json"
sudo sh -c 'echo \"exec-opts\": [\"native.cgroupdriver=systemd\"]  >>  /etc/docker/daemon.json'
sudo sh -c "echo }                                                 >>  /etc/docker/daemon.json"
# Flush changes and restart docker
sudo systemctl daemon-reload
sudo systemctl restart docker

# Configure Docker to start on boot: https://docs.docker.com/engine/install/linux-postinstall/#configure-docker-to-start-on-boot-with-systemd
# On Ubuntu it starts by default it says, but just to be sure:
sudo systemctl enable docker.service
sudo systemctl enable containerd.service
# Test installation:
sudo docker run hello-world

# ==== cri-dockerd ====
echo "==== Installing cri-dockerd ===="
# Next, install cri-dockerd: https://mirantis.github.io/cri-dockerd/usage/install/
# See release pages for specific version: https://github.com/Mirantis/cri-dockerd/releases
# Maybe helpful: https://www.mirantis.com/blog/how-to-install-cri-dockerd-and-migrate-nodes-from-dockershim/
# Version of cri-dockerd, and our Linux architecture, in this case amd64 with ubuntu
VERSION="0.3.17"
ARCH="amd64"
# This needs to be the exact name of the releases page
CRI_DOCKERD_PACKAGE="cri-dockerd-${VERSION}.${ARCH}"
# Download cri-dockerd (use -q for quite to avoid much output)
wget -q https://github.com/Mirantis/cri-dockerd/releases/download/v${VERSION}/${CRI_DOCKERD_PACKAGE}.tgz
# Unzip and move to correct folder (verify this by SSH into the node to see what is packaged if it does not work)
tar xvf ${CRI_DOCKERD_PACKAGE}.tgz
# Copy (force with -f) the executable to the bin folder. The actual executable is located inside the folder, so it has to be extracted from there.
sudo cp -f ./cri-dockerd/cri-dockerd /usr/local/bin/
# Make it executable
sudo chmod +x /usr/local/bin/cri-dockerd
# Verify installation:
cri-dockerd --help
# Cleanup after installation
rm -r ${CRI_DOCKERD_PACKAGE}.tgz
rm -r cri-dockerd

# Install and setup systemd service files:
sudo mkdir -p /etc/systemd/system
# (use -q for quite to avoid much output, but do show progress)
wget -q --show-progress https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.service
wget -q --show-progress https://raw.githubusercontent.com/Mirantis/cri-dockerd/master/packaging/systemd/cri-docker.socket
sudo mv cri-docker.socket cri-docker.service /etc/systemd/system/
sudo sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
# Start the service with cri-dockerd enabled
sudo systemctl daemon-reload
sudo systemctl enable cri-docker.service
sudo systemctl enable --now cri-docker.socket
# Verify socket is running and listening, should be: active (listening)
sudo systemctl status cri-docker.socket
# cri-docker.service is not necessary, since it does not run until something (like kubelet) connects to its socket, which you can see in above output, such as:
# Listen: /run/cri-dockerd.sock (Stream)
# But you can still view it here, but it will be inactive (dead) likely, which is expected and normal
# sudo systemctl status cri-docker.service

# ================================================ Install and Setup Kubernetes ================================================
echo "================= Installing and Setting up Kubernetes ================="
# Download the public signing key for the Kubernetes package repositories. 
# The same signing key is used for all repositories so you can disregard the version in the URL
# Note: In releases older than Debian 12 and Ubuntu 22.04, directory /etc/apt/keyrings does not exist by default, and it should be created before the curl command
# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
# sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/${KUBERNETES_VERSION}/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# Add the appropriate Kubernetes apt repository
# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update the apt package index, install kubelet, kubeadm and kubectl, and pin their version
# -qq suppresses all output except errors to avoid much outputs in the logs for clarity
sudo DEBIAN_FRONTEND=noninteractive apt-get update -qq -y
# This will install the latest patch version of v1.31 (since we added that to our apt package manager specifically above), such as v1.31.0, v1.31.1, 
# etc., depending on what's available at the time of install.
sudo DEBIAN_FRONTEND=noninteractive apt-get install -qq -y kubelet kubeadm kubectl
# This ensures that those three packages will not be automatically upgraded to newer versions by future apt upgrade runs to avoid incompatability between versions
sudo apt-mark hold kubelet kubeadm kubectl

# kubelet/kubernetes need to set swapoff
# https://github.com/kubernetes/kubernetes/issues/53533
sudo swapoff -a

# Start the kubelet service now, and make sure it starts automatically every time this machine reboots
sudo systemctl enable --now kubelet

# ================================================ Verify Cgroup drivers ================================================
echo "================= Verify Cgroup drivers ================="
# See: https://v1-31.docs.kubernetes.io/docs/tasks/administer-cluster/kubeadm/configure-cgroup-driver/
# Recommended with kubernetes v1.31 is to use the stystemd cgroup driver, which is the default from kubernetes v1.22 and later:
# https://v1-31.docs.kubernetes.io/docs/setup/production-environment/container-runtimes/#systemd-cgroup-driver 

# Verify cgroup drivers are systemd:
# Docker Container Runtime, this is the most important, probably kubeadm will detect it automatically from this container runtime
echo "Docker (container runtime) cgroup driver: "
sudo docker info | grep -i cgroup

echo "Configuration for this node complete."

# Everything inside this block (stdout and stderr) will be piped and logged
# The line below does the following:
# - 2>&1 : Redirects stderr (2) to stdout (1), combining output and errors
# - | tee -a : Pipes combined output to both the terminal and the log file
# - config_k8s_node.log : Appends all logs to this file
} 2>&1 | tee -a config_k8s_node.log
