# Setup Kubernetes
This file explains how to setup DYNAMOS in the configured Kubernetes environment in the previous steps for FABRIC.

This guide assumes that you followed the steps in the notebook for each step below.

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
./upload_to_remote.sh ../../configuration ~/.ssh/slice_key ../fabric_config/ssh_config_upload_script ubuntu dynamos-node "~/DYNAMOS"

# Upload the charts folder in the DYNAMOS folder, such as (replace IP of course in the ssh_config file below if necessary):
TODO
```
Note: when making changes, the changed files need to be uploaded to the VM again before executing them.

TODO: how to apply charts to specific nodes? Use Helm commands or?
TODO: custom charts? If so, copy charts folder into this folder for DYNAMOS in fabric.

TODO: further steps after that for energy monitoring, such as Kepler, etc., see energy-efficiency folder