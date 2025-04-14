# Setup Kubernetes
This file explains how to setup DYNAMOS in the configured Kubernetes environment in the previous steps for FABRIC.

This guide assumes that you followed the steps in the notebook for each step below.

## Problems with IPv4 image pulls and connectivity
```sh
curl -v https://cr.l5d.io/v2/

# 
ssh -J bastion-1.fabric-testbed.net -R localhost:4567:localhost:5678 <vm IPv6 address>
```


## Install Linkerd
Do these steps manually after SSH into the k8s-control-plane node:
```sh
# Set Linkerd version
export TEMP_LINKERD_VERSION=edge-25.4.1

# Preload critical images manually to avoid FABRIC network issue to uncommon registries like cr.l5d.io (see Troubleshooting.md):
# Load those images with docker from the publicly available GitHub registry: https://github.com/orgs/linkerd/packages
images=(
  proxy:$TEMP_LINKERD_VERSION
  proxy-init:v2.4.1
  controller:$TEMP_LINKERD_VERSION
  policy-controller:$TEMP_LINKERD_VERSION
)
for image in "${images[@]}"; do
  sudo docker pull ghcr.io/linkerd/$image
done

# See: https://linkerd.io/2.17/getting-started/
# Install CLI (using a specific stable version)
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install-edge | LINKERD2_VERSION=$TEMP_LINKERD_VERSION sh

# Add Linkerd to PATH
export PATH=$HOME/.linkerd2/bin:$PATH
# Check version to verify installation:
linkerd version

# install the GatewayAPI CRDs (required for linkerd, as output by the command after installing the CLI)
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml

# Validate cluster before installing linkerd:
linkerd check --pre

# Install Linkerd on cluster
# Install Linkerd CRDs
linkerd install --crds | kubectl apply -f -
# TODO: first with yaml install:
linkerd install \
  --set proxyInit.runAsRoot=true \
  --set nodeSelector."kubernetes\\.io/hostname"=dynamos-core \
  > linkerd.yaml
# Install Linkerd control plane pinned to dynamos-core node (// escapes the .)
# linkerd install \
#   --set nodeSelector."kubernetes\\.io/hostname"=dynamos-core \
#   | kubectl apply -f -
linkerd install \
  --set proxyInit.runAsRoot=true \
  --set nodeSelector."kubernetes\\.io/hostname"=dynamos-core \
  | kubectl apply -f -

# Check cluster
linkerd check

# Install Jaeger onto the cluster for observability
# Install Jaeger on the same node
linkerd jaeger install \
  --set nodeSelector."kubernetes\\.io/hostname"=dynamos-core \
  | kubectl apply -f -

# Optionally install for insight dashboard - not currently in use
# linkerd wiz install | kubectl apply -f -

# Note: you can debug with commands like:
# kubectl describe pod linkerd-destination-77b8ff9d69-l2z4k -n linkerd
# To reset:
# # To remove Linkerd Viz
# linkerd viz uninstall | kubectl delete -f -
# # To remove Linkerd Jaeger
# linkerd jaeger uninstall | kubectl delete -f 
# # Remove control plane:
# linkerd uninstall | kubectl delete -f -
```
TODO: can do with a script? When I did it before with a script I got errors and the pods were not running.


## Upload the configuration files and charts to the kubernetes control-plane node
Make sure you have SSH access to the node (explained in the k8s-setup.ipynb notebook in the previous step). After that, execute the following steps.

Prepare the Kubernetes control-plane node for DYNAMOS:
```sh
# SSH into the kubernetes control-plane node.
# Create DYNAMOS folder on the control-plane node for the DYNAMOS application:
mkdir -p DYNAMOS

# Go to the correct directory in this project, such as in a VSC terminal in WSL:
cd fabric/scripts
# Upload the configuration folder for DYNAMOS to the kubernetes control-plane node, such as (replace IP of course in the ssh_config file below if necessary):
./upload_to_remote.sh ../../configuration ~/.ssh/slice_key ../fabric_config/ssh_config_upload_script ubuntu dynamos-node "~/DYNAMOS"
```
Note: this uses a different ssh_config file specific for the nodes, otherwise, it encountered an error such as "ssh: Could not resolve hostname bastion.fabric-testbed.net: Temporary failure in name resolution". Do not forget to change the IP when new nodes are created in FABRIC.

Then upload the actual files for DYNAMOS in FABRIC specifically:
```sh
# Replace the congiguration script in this folder with the FABRIC specific configuration script, such as (replace IP of course in the ssh_config file below if necessary):
./upload_to_remote.sh ../../charts ~/.ssh/slice_key ../fabric_config/ssh_config_upload_script ubuntu dynamos-node "~/DYNAMOS"

# Upload the charts folder in the DYNAMOS folder, such as (replace IP of course in the ssh_config file below if necessary):
./upload_to_remote.sh ../dynamos/dynamos-configuration.sh ~/.ssh/slice_key ../fabric_config/ssh_config_upload_script ubuntu dynamos-node "~/DYNAMOS/configuration"

# TODO: then manually start the configuration script. Make sure docker is logged in after:
docker login
```
Note: when making changes, the changed files need to be uploaded to the VM again before executing them.

TODO: how to apply charts to specific nodes? Use Helm commands or?
TODO: custom charts? If so, copy charts folder into this folder for DYNAMOS in fabric.

TODO: further steps after that for energy monitoring, such as Kepler, etc., see energy-efficiency folder