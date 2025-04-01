# Setup Kubernetes
This file explains how to setup Kubernetes in FABRIC.

Note: this guide used WSL for the underlying testing and validation.

TODO: explain here how to do that.


## Configure Kubernetes environment
In a Linux terminal (e.g. WSL), execute the following commands:
```sh
# Navigate to the fabric folder
cd fabric

# Clone Kubespray
git clone https://github.com/kubernetes-sigs/kubespray.git
cd kubespray
# Use stable version (this checks out the branch of kubespray called release-x)
git checkout release-2.27
# Install requirements (this will install ansible as well)
pip3 install  -r ./requirements.txt

# Set up your inventory for your cluster (will create files in fabric/kubespray/inventory/x)
cp -rfp inventory/sample inventory/dynamos-cluster
```
