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

## Installing Protoc (WSL) and libraries for Go and Python
```sh
# Open wsl
wsl
# Install protoc: https://grpc.io/docs/protoc-installation/
# Example:
sudo apt install -y protobuf-compiler
# Verify installation:
protoc --version

# To compile the proto file for Go file we need the Protobuf Compiler(protoc) and also the protoc-gen-go plugin:
go install google.golang.org/protobuf/cmd/protoc-gen-go@latest
# We also need protoc-gen-go-grpc:
go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
# This will install it in $GOPATH/bin. Verify installed file by running:
which protoc-gen-go
which protoc-gen-go-grpc
# Or you can see them listed with ls
echo $GOPATH
cd $GOPATH/bin
ls

# Make sure you have GOPATH set in .bashrc:
cd ~
explorer.exe .
# Select .bashrc and open it (click Allow when asked). Make sure the following lines for Go are present:
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin
# Reload file contents source ~/.bashrc

# For Python you can use pip to install the required library
# It is important to install these versions specifically, as they are used for DYNAMOS later.
pip install grpcio==1.59.3
pip install grpcio-tools==1.59.3
# Verify installation:
python3 -m grpc_tools.protoc --version
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
In short:
```sh
# Use brew on Linux for this:
brew install derailed/k9s/k9s
```
HINT: When running k9s, it will initially load the default namespaces, press 0 to show all namespaces, which your containers are likely going to show up in.


## Install etcdctl for WSL (optional)
Use this guide: https://etcd.io/docs/v3.5/install/
In short:
```sh
# Use brew on Linux for this:
brew install etcd
```