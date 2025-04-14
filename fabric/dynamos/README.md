# Setup Kubernetes
This file explains how to setup DYNAMOS in the configured Kubernetes environment in the previous steps for FABRIC.

This guide assumes that you followed the steps in the notebook for each step below.

## Upload the configuration files and charts to the kubernetes control-plane node
Make sure you have SSH access to the node (explained in the k8s-setup.ipynb notebook in the previous step). After that, execute the following steps:
```sh
# Create DYNAMOS folder on the control-plane node for the DYNAMOS application:
TODO
# Upload the configuration folder for DYNAMOS to the kubernetes control-plane node:
TODO
# Replace the congiguration script in this folder with the FABRIC specific configuration script:
TODO

# Upload the charts folder in the DYNAMOS folder
```
TODO: how to apply charts to specific nodes? Use Helm commands or?
TODO: custom charts? If so, copy charts folder into this folder for DYNAMOS in fabric.

TODO: further steps after that for energy monitoring, such as Kepler, etc., see energy-efficiency folder