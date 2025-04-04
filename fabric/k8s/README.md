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

## Configure Kubernetes cluster/environment
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
Make sure to first follow the steps from the k8s_setup.ipynb notebook, specifically the SSH setup steps to connect to the VMs.

Then verify a few steps before doing the following steps:
```sh
# Verify you can ssh into all the nodes (or a subset is also enough), using the commands provided from the Notebook step (see steps in notebook), such as:
ssh -i ~/.ssh/slice_key -F ssh_config ubuntu@2001:610:2d0:fabc:f816:3eff:fe65:a464
# Inside each node, test if they can reach the other two nodes with the IP address, such as:
ping 2001:610:2d0:fabc:f816:3eff:fe65:a464
# It works if you receive results, such as "64 bytes from 2001:610:2d0:fabc:f816:3eff:fe95:d90f: icmp_seq=1 ttl=64 time=0.402 ms" 
# You can use ctrl+c to exit
# Note: IPv4 will probably not work in FABRIC, such as:
ping 10.30.6.107
# This will likely give nothing back and timeout eventually
```
After these steps, you can move to the next step below.

In a Linux terminal (e.g. WSL), execute the following commands to use Kubespray to setup the Kubernetes cluster:
```sh
# Go into the kubespray directory
cd fabric/kubespray

# Set up your inventory for your cluster (will create files in fabric/kubespray/inventory/x)
cp -rfp inventory/sample inventory/dynamos-cluster
# Then add the inventory.ini file in the created dynamos-cluster folder. The k8s_setup.ipynb notebook gets the necessary information
# It is important to use the correct IPs: the IPv6, such as: 2001:610:2d0:fabc:f816:3eff:fe65:a464, since it is not reachable with the IPv4 in FABRIC.

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
# Use the slice key here as the private key to connect to the nodes from the slice in FABRIC
# Use username ubuntu (-u), this is the same as the local ssh command used to log into the VM
ansible-playbook -i inventory/dynamos-cluster/inventory.ini cluster.yml -b -v --private-key=~/.ssh/slice_key -u ubuntu
# Next, you can follow the subsequent step in the k8s_setup.ipynb notebook

# You can run the above command with some modifications to test variables, such as:
# This command is used to test if a variable is loaded from the group_vars in the inventory file (change node1 to something else, such as etcd) 
ansible -i inventory/dynamos-cluster/inventory.ini node1 \
  -m debug -a "var=etcd_listen_client_urls" \
  --private-key=~/.ssh/slice_key
# TODO: test

# If things fail and you need to fix that in between, use the reset.yml to reset the cluster first before trying again the above command
# This is because if some things failed mid-deploy, such as etcd, it might conflict/skip important files, etc.
# This automatically prompts yes to continue without manual intervention required
ansible-playbook -i inventory/dynamos-cluster/inventory.ini reset.yml -b -v --private-key=~/.ssh/slice_key -u ubuntu -e reset_confirmation=yes

# TODO: now it works mostly, only error now:
TASK [etcd : Configure | Ensure etcd is running] ********************************************************************************************************************************************
fatal: [node1]: FAILED! => {"changed": false, "msg": "Unable to start service etcd: Job for etcd.service failed because the control process exited with error code.\nSee \"systemctl status etcd.service\" and \"journalctl -xe\" for details.\n"}
```

### Troubleshooting
#### etcd problems:
If you encounter problems with etcd, such as during kubespray cluster configuration, these steps might help:
```sh
# SSH into the control plane using the SSH command from earlier for node1

# Show status
sudo systemctl status etcd.service
# Show last 50 log lines
sudo journalctl -u etcd.service -n 50 --no-pager
# These logs can be used for further debugging
# You can use this command to see some configurations for example:
sudo cat /etc/systemd/system/etcd.service

# Examples:
{"level":"warn","ts":"2025-04-04T09:31:28.416172Z","caller":"etcdmain/etcd.go:75","msg":"failed to verify flags","error":"invalid value \"https://2001:610:2d0:fabc:f816:3eff:fe65:a464:2380\" for ETCD_LISTEN_PEER_URLS: URL address does not have the form \"host:port\": https://2001:610:2d0:fabc:f816:3eff:fe65:a464:2380"}
# Fix: added to kubespray/inventory/dynamos-cluster/group_vars//etcd/k8s-cluster.yml some additions to allow correct read of IPv6 address:
# In FABRIC, we use IPv6, such as: 2001:610:2d0:fabc:f816:3eff:fe65:a464
# So the IP has to be enclosed in [], using the ip address value from the .ini file, otherwise it will cause errors for etcd
etcd_listen_client_urls: "https://[{{ ip }}]:2379"
etcd_advertise_client_urls: "https://[{{ ip }}]:2379"
etcd_listen_peer_urls: "https://[{{ ip }}]:2380"
etcd_initial_advertise_peer_urls: "https://[{{ ip }}]:2380"
# TODO: did that work?
```

