#!/bin/bash

{

echo "==== Starting post-install script for Kubespray cluster ===="

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

# === Cluster checks ===
# Wait briefly to ensure Kubernetes components have time to stabilize
echo "Waiting briefly for cluster to stabilize..."
sleep 10

# Display the status of all nodes
echo "Checking Kubernetes nodes..."
kubectl get nodes -o wide

# Display the status of all system-level pods
echo "Checking pods in kube-system namespace..."
kubectl get pods -n kube-system -o wide

# List all pods in all namespaces
echo "Listing all pods across all namespaces..."
kubectl get pods --all-namespaces -o wide

# === Pods per Node Summary ===
echo "Pods per node:"
kubectl get pods -A -o wide | awk 'NR>1 {print $8}' | sort | uniq -c | sort -nr | awk '{print "Node " $2 ": " $1 " pods"}'

# === Brew on Linux installation (used for easier installation of other packages) ===
echo "Checking for Homebrew..."

# Manually add brew to PATH and environment for this script run
# This is necessary because this is a non-interactive terminal in Jupyter Hub when running this script on the FABRIC node, so it will not see 
# the brew installation otherwise. And you cannot do "source ~/.bashrc" as well here because of the non-interactive mode.
if [ -f /home/linuxbrew/.linuxbrew/bin/brew ]; then
  echo "Loading Homebrew environment..."
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
# Debug print
brew --version || echo "brew not found"

if ! command -v brew >/dev/null 2>&1; then
  echo "Installing Homebrew on Linux..."
  # "</dev/null" here tells the script to not ask for input (otherwise will ask for root password). This is necessary because here root access on FABRIC nodes is
  # already allowed, so not necessary here. This also avoids problems with input, because the root password is not known to public in FABRIC by default
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" </dev/null

  # Configuration steps (displayed after running the above command):
  echo >> /home/ubuntu/.bashrc
  echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> /home/ubuntu/.bashrc
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  # Recommended steps:
  # Use -y to ensure it does yes when prompted
  sudo apt update -y
  sudo apt-get install -y build-essential
  brew install gcc

  echo "Homebrew installed and configured."

  # Optional: verify it works (can be removed or replaced)
  # echo "Verifying brew with test install..."
  # brew install hello
else
  echo "Homebrew already installed, skipping..."
fi

# === K9s Installation ===
echo "Installing k9s..."
if ! command -v k9s >/dev/null 2>&1; then
  # Use brew to install k9s
  brew install derailed/k9s/k9s
  echo "k9s installed."
else
  echo "k9s is already installed, skipping..."
fi

# === Etcd Installation ===
echo "Installing Etcd..."
if ! command -v etcd >/dev/null 2>&1; then
  # Use brew to install k9s
  brew install etcd
  echo "etcd installed."
else
  echo "etcd is already installed, skipping..."
fi

# === Helm Installation ===
echo "Installing Helm (Kubernetes package manager)..."
if ! command -v helm >/dev/null 2>&1; then
  brew install helm
  echo "Helm installed."
else
  echo "Helm is already installed, skipping..."
fi

echo "Kubespray control plane post-setup complete."
# Use "" around ~ to avoid it resolving to the current home directory
echo "Make sure to run "source "~/.bashrc"" in any SSH session you have open to reload the PATH variables to be able to use the installations."

# Everything inside this block (stdout and stderr) will be piped and logged
# The line below does the following:
# - 2>&1 : Redirects stderr (2) to stdout (1), combining output and errors
# - | tee -a : Pipes combined output to both the terminal and the log file
# - config_control_plane.log : Appends all logs to this file
} 2>&1 | tee -a config_control_plane.log
