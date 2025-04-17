#!/bin/bash

# This script is used to install linkerd on the DYNAMOS Kubernetes cluster

# See: https://linkerd.io/2.17/getting-started/
# Install CLI (using a specific stable version)
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install-edge | LINKERD2_VERSION=edge-25.4.1 sh

# Add Linkerd to PATH in a persistent way (export would not work in noninteractive mode), assuming an Ubuntu OS for .bashrc:
# (This uses the shown export command after the above command, and adds it to the shell rc)
echo 'export PATH=$PATH:/home/ubuntu/.linkerd2/bin' >> ~/.bashrc
# Load the shell rc to apply changes in any termainl session your run with: source ~/.bashrc
# However, in this noninteractive mode in Jupyter notebook, it does not persist, so also add it manually for this script:
export PATH=$PATH:/home/ubuntu/.linkerd2/bin

# Check version to verify installation:
linkerd version

# install the GatewayAPI CRDs (required for linkerd, as output by the command after installing the CLI)
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml

# Validate cluster before installing linkerd:
linkerd check --pre

# Install Linkerd on cluster
# Install Linkerd CRDs
linkerd install --crds | kubectl apply -f -
# Install Linkerd control plane pinned to dynamos-core node (// escapes the .)
# (you can list labels of nodes with: kubectl get nodes --show-labels)
linkerd install \
  --set proxyInit.runAsRoot=true \
  --set nodeSelector."kubernetes\\.io/hostname"=dynamos-core \
  | kubectl apply -f -

# Wait shortly before applying the check to make sure everything is running (or almost running)
sleep 10

# Check cluster
linkerd check

# Install Jaeger onto the cluster for observability
# Install Jaeger on the same node
# This requires a specific setup, see the nodeSelector options in https://github.com/linkerd/linkerd2/blob/main/jaeger/charts/linkerd-jaeger/values.yaml
linkerd jaeger install \
  --set collector.nodeSelector."kubernetes\\.io/hostname"=dynamos-core \
  --set nodeSelector."kubernetes\\.io/hostname"=dynamos-core \
  --set jaeger.nodeSelector."kubernetes\\.io/hostname"=dynamos-core \
  --set webhook.nodeSelector."kubernetes\\.io/hostname"=dynamos-core \
  | kubectl apply -f -

# Optionally install for insight dashboard - not currently in use
# linkerd wiz install | kubectl apply -f -

# Note: you can debug with commands like:
# kubectl describe pod linkerd-destination-77b8ff9d69-l2z4k -n linkerd
# To reset:
# # To remove Linkerd Viz
# linkerd viz uninstall | kubectl delete -f -
# # To remove Linkerd Jaeger
# linkerd jaeger uninstall | kubectl delete -f -
# # Remove control plane:
# linkerd uninstall | kubectl delete -f -