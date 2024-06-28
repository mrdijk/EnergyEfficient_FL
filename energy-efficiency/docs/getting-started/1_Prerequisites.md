# Preparation (installing prerequisites)
It is recommended to use WSL (Linux OS). Install WSL and open the terminal, for example in VSC, by running:
```sh
wsl
```

## Install Go
1. Check the latest go version: https://go.dev/dl/

2. Execute these commands individually:
```sh
# Install Go
# e.g. wget https://dl.google.com/go/go1.22.4.linux-amd64.tar.gz
wget https://dl.google.com/go/<version>.linux-amd64.tar.gz
# e.g. sudo tar -xvf go1.22.4.linux-amd64.tar.gz
sudo tar -xvf <version>.linux-amd64.tar.gz
sudo mv go /usr/local

# Open .bashrc file
cd ~
explorer.exe .

# Add following lines at the bottom and save the file.
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# Refresh terminal
exit
# Reopen terminal
wsl
# Check go version to verify installation
go version

# Then you can remove the downloaded tar file from step 1 if you want, this is not required anymore after unpacking it.
```

## Install make
```sh
# Open wsl
wsl
# Install make
sudo apt install make
```

## Installing and running Kubernetes
1. Make sure Docker is installed: https://docs.docker.com/desktop/
(And the Docker Desktop is using WSL2 as backend: https://docs.docker.com/desktop/wsl/).

2. Make sure Kubernetes is installed (kubectl and minikube for local development). 

Install minikube (local Kubernetes development): https://minikube.sigs.k8s.io/docs/start/?arch=%2Flinux%2Fx86-64%2Fstable%2Fbinary+download. Setup cgroupv2 driver (see Configure_cgroupv2.md file for a tutorial).

Install kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/

3. Make sure Kubernetes is running (keep in mind again: use WSL):
```sh
minikube start --driver=docker
```
Make sure the Docker engine is running (open Docker Desktop).

## Install Helm (package manager for Kubernetes)
Install the package manager for Kubernetes: https://helm.sh/docs/intro/install/#from-script

Then restart all terminals and verify the installation by running:
```sh
helm version
```

## Install Linkerd
Follow this guide: https://linkerd.io/2.15/getting-started/#step-1-install-the-cli

Then restart all terminals and verify the installation by running:
```sh
linkerd version
```
