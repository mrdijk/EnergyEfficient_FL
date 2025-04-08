# Setup Kubernetes
This file explains how to setup Kubernetes in FABRIC.

Note: this guide used WSL for the underlying testing and validation.

## SSH 
You can configure SSH to access the VMs by following the steps in the k8s-setup.ipynb notebook file. 

### Test root access
To test root access, run the following commands:
```sh
# After SSH access into the VM, run:
sudo whoami
# If it returns the following for example it means you have root access, meaning the ubuntu VM has passwordless sudo working correctly on the node:
ubuntu@Node2:~$ sudo whoami
root
``` 

## Configure Kubernetes cluster/environment
### Preparing Kubespary
In a Linux terminal (e.g. WSL), execute the following commands to prepare Kubespray for usage:
```sh
# Navigate to the fabric folder
cd fabric

# Use custom script to prepare kubespray, fetching the code from GitHub and cleaning up unnecessary files
./k8s/cluster-setup/prepare_kubespray.sh
```
Now, when you want a new Kubespray version you can follow these steps again, but keep in mind that the local changes might get lost, so make a copy of those before doing this script.  Also, keep in mind that the script is specific for a version of Kubespray, files may be renamed or added, etc., so the script section removing files may need to be slightly altered when updating versions.

This seutp allows for easily configuring Kubespray with only the necessary files and saving changes in this GitHub repository for this project without interference or more manual steps to set it up in the future, etc.

In the future, you can also update it by deleting the kubespray directory and executing the script again. Then you can see the changed files with the help of the source control in VSC for example, since you have it stored in GitHub, and now you can see your changes before committing. Then you can decide whether to accept the changes from kubespray or not. But it is not required to update it, you can do this if you want any specific changes for example, however, avoid this if you have a working version to avoid unexpected behaviour and changes, etc.


### Create the DYNAMOS cluster inventory for Kubespray & Verify connections
Make sure you followed the steps to configure the network from the k8s_setup.ipynb notebook, specifically the network setup to add the IP addresses. These IP addresses can be used in the inventory file for kubespray.

In a Linux terminal (e.g. WSL), execute the following commands:
```sh
# Go into the kubespray directory
cd fabric/kubespray

# Set up your inventory for your cluster (will create files in fabric/kubespray/inventory/x)
cp -rfp inventory/sample inventory/dynamos-cluster
```
Then add the IP addresses to the inventory.ini file in the created dynamos-cluster folder. The k8s_setup.ipynb notebook gets the necessary information you can use for this.

Then run the SSH commands described in the k8s_setup.ipynb notebook, specifically specifically the SSH setup steps to connect to the VMs. This is used to test the connection to the nodes from IPv4.

Then verify a few steps before doing the following steps:
```sh
# Verify you can ssh into all the nodes (or a subset is also enough), using the commands provided from the Notebook step (see steps in notebook), such as:
ssh -i ~/.ssh/slice_key -F ssh_config ubuntu@2001:610:2d0:fabc:f816:3eff:fe65:a464

# Inside each node, test if they can reach the other two nodes with the IP address, such as:
ping 10.145.5.3
# It works if you receive results, such as "64 bytes from 2001:610:2d0:fabc:f816:3eff:fe95:d90f: icmp_seq=1 ttl=64 time=0.402 ms" 
# You can use ctrl+c to exit
# If it does not work, it shows nothing and maybe times out eventually
```
After these steps, you can move to the next step below.


### Uploading kubespray to the control plane node & Configure Control plane node
Execute the following steps to upload kubespray to the remote VM:
```sh
# Go to the correct directory:
cd fabric/scripts
# Execute the script, such as (replace IP of course):
./upload_to_remote.sh ../kubespray ~/.ssh/slice_key ../fabric_config/ssh_config ubuntu 2001:610:2d0:fabc:f816:3eff:fe03:f07c

# In the future you can also only now replace specific files to avoid having to reupload the whole directory, such as (replace IP of course):
./upload_to_remote.sh ../kubespray/ansible.cfg ~/.ssh/slice_key ../fabric_config/ssh_config ubuntu 2001:610:2d0:fabc:f816:3eff:fe03:f07c "~/kubespray"
# Or:
./upload_to_remote.sh ../kubespray/inventory/dynamos-cluster/inventory.ini ~/.ssh/slice_key ../fabric_config/ssh_config ubuntu 2001:610:2d0:fabc:f816:3eff:fe03:f07c "~/kubespray/inventory/dynamos-cluster"
# Note: "" around ~ is used to avoid resolving the ~ to the local user's home directory (see explanation in the script)
# You can verify the files by going to the remote host and using cat to view the file for example, such as:
# SSH into the VM and go to the correct path, such as:
cd /home/ubuntu/kubespray
cat ansible.cfg
# Or:
cat inventory/dynamos-cluster/inventory.ini
```

Then execute the steps in the k8s_setup.ipynb to configure kubespray on the remote host with the corresponding script.

Then you can configure the control plane node:
```sh
# First, make sure you followed the step in the k8s_setup.ipynb to execute the script for kubespray configuration.
# This is an important step to install the dependencies, such as ansible, etc. Then follow the next steps below:

# SSH into the control plane node, such as (replace IP of course):
ssh -i ~/.ssh/slice_key -F ssh_config ubuntu@2001:610:2d0:fabc:f816:3eff:fe03:f07c
# Add SSH slice key to connect between the nodes in FABRIC (make sure you followed the SSH config steps from the k8s_setup.ipynb notebook):
mkdir -p ~/.ssh
# Copy the files from your local directory to the remote host, such as (replace IP of course), this needs to be run from localhost, not in SSH on the remote:
./upload_to_remote.sh ~/.ssh/slice_key ~/.ssh/slice_key ../fabric_config/ssh_config ubuntu 2001:610:2d0:fabc:f816:3eff:fe03:f07c "~/.ssh"
```

### Using Kubespray
Make sure you followed the above steps.

Note: when making changes, do not forget to upload the kubespray changes to the remote host controle plane (in this case node1)! Otherwise, the changes will not apply. For example, reupload the whole kubespray file with several files changed, and only a file when only one file changed, etc.

In a Linux terminal (e.g. WSL), configure the kubernetes cluster from the remote host after following the above steps
```sh
# Before running these commands, make sure you SSH into the control plane node (see above commands for examples).
# Then go to the kubespray directory and source the virtual python environment:
cd kubespray
# First activate the venv to have dependencies such as ansible available (this is not present in the kubespray directory for specific reasons, see configure_remote_kubespray.sh). This loads it from the kubespray directory.
source ../kubespray-venv/bin/activate
# Then you can execute the following commands:
# TODO: test uploading kubespray again and then test with new script to run ansible.

# No need to use the ssh_config, since this is now executed from the nodes already, so no bastion needed to connect to the FABRIC nodes 
# However, we do need to use slice_key, because without it you get permission denied from accessing the nodes
# Then execute the playbook to configure the cluster, this takes a while to execute, the more nodes the longer it takes
# -b: Tells Ansible to use become (i.e., use sudo) for privilege escalation on remote machines
# -v: Runs in verbose mode, showing more output (you can add more vs for even more detail, like -vv or -vvv)
# Use the slice key here as the private key to connect to the nodes from the slice in FABRIC
# Use username ubuntu (-u), this is the same as the local ssh command used to log into the VM
ansible-playbook -i inventory/dynamos-cluster/inventory.ini cluster.yml -b -v -u ubuntu --private-key=~/.ssh/slice_key

# If things fail and you need to fix that in between, use the reset.yml to reset the cluster first before trying again the above command
# This is because if some things failed mid-deploy, such as etcd, it might conflict/skip important files, etc.
# Note: this is not always necessary, for some minor changes you can maybe just rerun the cluster command above and restart the pods with k9s for example
# This automatically prompts yes to continue without manual intervention required
ansible-playbook -i inventory/dynamos-cluster/inventory.ini reset.yml -b -v --private-key=~/.ssh/slice_key -u ubuntu -e reset_confirmation=yes

# You can run the above command with some modifications to test variables, such as:
# This command is used to test if a variable is loaded from the group_vars in the inventory file (you can change all to a more specific one such as node1) 
ansible -i inventory/dynamos-cluster/inventory.ini all \
  -m debug -a "var=enable_dual_stack_networks" \
  --private-key=~/.ssh/slice_key
```
After exeucting kubespray to configure the cluster, you can follow the next steps in the k8s_setup.ipynb notebook.


### Troubleshooting
See the Troubleshooting.md file.
