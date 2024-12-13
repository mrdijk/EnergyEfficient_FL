# Preparation (installing prerequisites)
It is recommended to use WSL (Linux OS). Install WSL and open the terminal, for example in VSC, by running:
```sh
wsl
```

Follow this guide to install prerequisites for DYNAMOS: https://github.com/Jorrit05/DYNAMOS?tab=readme-ov-file#prerequisite-software-tools

Extra explanation for what to do from this guide precisely is below, follow closely. Other things are not necessary from the above installation guide.

## Install Go in WSL
Follow instructions: https://go.dev/doc/install

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

2. Make sure Kubernetes is installed (kubectl and Kubernetes enabled in Docker Desktop for local development). 
Follow this guide on how to enable Kubernetes in Docker Desktop: https://docs.docker.com/desktop/features/kubernetes/
Specifically, also use kubectl with it, and set the context to docker-desktop, like explained in the guide.


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

## Install Brew on WSL
Use this guide: https://docs.brew.sh/Homebrew-on-Linux

## Install k9s for WSL (optional)
Use this guide: https://k9scli.io/topics/install/
