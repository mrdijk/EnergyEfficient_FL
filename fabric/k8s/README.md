# Setup Kubernetes
This file explains how to setup Kubernetes in FABRIC.

Note: this guide used WSL for the underlying testing and validation.

TODO: explain here how to do that.

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

## Configure Kubernetes environment
### Preparing Kubespary
In a Linux terminal (e.g. WSL), execute the following commands to prepare Kubespray for usage:
```sh
# Navigate to the fabric folder
cd fabric

# Use custom script to prepare kubespray, fetching the code from GitHub and cleaning up unnecessary files
./k8s/prepare_kubespray.sh
```
Now, when you want a new Kubespray version you can follow these steps again, but keep in mind that the local changes might get lost, so make a copy of those before doing this script.  Also, keep in mind that the script is specific for a version of Kubespray, files may be renamed or added, etc., so the script section removing files may need to be slightly altered when updating versions.

This seutp allows for easily configuring Kubespray with only the necessary files and saving changes in this GitHub repository for this project without interference or more manual steps to set it up in the future, etc.

### Using Kubespray
TODO: explain here to use the k8s-setup.ipynb notebook first.

In a Linux terminal (e.g. WSL), execute the following commands to use Kubespray to setup the Kubernetes cluster:
```sh
# Go into the kubespray directory
cd fabric/kubespray

# Set up your inventory for your cluster (will create files in fabric/kubespray/inventory/x)
cp -rfp inventory/sample inventory/dynamos-cluster
# Then add the inventory.ini file in the created dynamos-cluster folder. The k8s_setup.ipynb notebook gets the necessary information

# Configure the Ansible config file (by default it does not allow it in the working directory: https://docs.ansible.com/ansible/devel/reference_appendices/config.html#cfg-in-world-writable-dir)
# For example:
export ANSIBLE_CONFIG=/mnt/c/Users/cpoet/VSC_Projs/EnergyEfficiency_DYNAMOS/fabric/kubespray/ansible.cfg
# Otherwise, it will give the warning: 
[WARNING]: Ansible is being run in a world writable directory
(/mnt/c/Users/cpoet/VSC_Projs/EnergyEfficiency_DYNAMOS/fabric/kubespray), ignoring it as an ansible.cfg source. For more
information see https://docs.ansible.com/ansible/devel/reference_appendices/config.html#cfg-in-world-writable-dir
# Resulting in ERROR! the role 'kubespray-defaults' was not found

# Then execute the playbook to configure the cluster, this takes a while to execute, the more nodes the longer it takes
# -b: Tells Ansible to use become (i.e., use sudo) for privilege escalation on remote machines
# -v: Runs in verbose mode, showing more output (you can add more vs for even more detail, like -vv or -vvv)
ansible-playbook -i inventory/dynamos-cluster/inventory.ini cluster.yml -b -v --private-key=~/.ssh/slice_key
# TODO: problem is that Ansible now does not use a bastion correctly yet, that is the difference when I connect with SSH from a command line and executing the above Ansible script.
# TODO: add that in explanation.
# TODO: now added the ssh_config, but it still does not see that bastion.

```
