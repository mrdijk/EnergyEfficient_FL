# Archive: old versions
This folder describes old versions we had that we spend time on and therefore kept in this repository.

Below are old documentations, while the rest of this folder contains old solutions, such as an old kubespray solution.

# Old Kubernetes cluster setup with Kubespray from local machine:
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
# Note: IPv4 will probably not work in FABRIC by default, such as:
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
# It is important to use the correct IPs: the IPv6, such as: 2001:610:2d0:fabc:f816:3eff:fe65:a464, since it is not reachable with the IPv4 in FABRIC by default.

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
# This command is used to test if a variable is loaded from the group_vars in the inventory file (you can change all to a more specific one such as node1) 
ansible -i inventory/dynamos-cluster/inventory.ini all \
  -m debug -a "var=ntp_enabled" \
  --private-key=~/.ssh/slice_key

# If things fail and you need to fix that in between, use the reset.yml to reset the cluster first before trying again the above command
# This is because if some things failed mid-deploy, such as etcd, it might conflict/skip important files, etc.
# This automatically prompts yes to continue without manual intervention required
ansible-playbook -i inventory/dynamos-cluster/inventory.ini reset.yml -b -v --private-key=~/.ssh/slice_key -u ubuntu -e reset_confirmation=yes

# now it works mostly, only error now, so need to come up with something else:
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
# This was due to IPv6 addresses having a specific format. In FABRIC, we use IPv6, such as: 2001:610:2d0:fabc:f816:3eff:fe65:a464
# So, the IP should be enclosed in [] to make that work. However, more broad problems with using IPv6 was discovered, so a different solution was done, which is now the current setup.
```

# Old Kubespray configure with Ubuntu 22 image on FABRIC:
### Uploading kubespray to the control plane node & Configure Control plane node
Execute the following steps to upload kubespray to the remote VM:
```sh
# Go to the correct directory:
cd fabric/scripts
# Execute the script, such as (replace IP of course):
./upload_to_remote.sh ../kubespray ubuntu 2001:610:2d0:fabc:f816:3eff:feba:b846 ~/.ssh/slice_key ../fabric_config/ssh_config

# In the future you can also only now replace specific files to avoid having to reupload the whole directory, such as (replace IP of course):
./upload_to_remote.sh ../kubespray/ansible.cfg ubuntu 2001:610:2d0:fabc:f816:3eff:feba:b846 ~/.ssh/slice_key ../fabric_config/ssh_config "~/kubespray"
# Or:
./upload_to_remote.sh ../kubespray/inventory/dynamos-cluster/inventory.ini ubuntu 2001:610:2d0:fabc:f816:3eff:fe0f:e479 ~/.ssh/slice_key ../fabric_config/ssh_config "~/kubespray/inventory/dynamos-cluster"
# Note: "" around ~ is used to avoid resolving the ~ to the local user's home directory (see explanation in the script)
# You can verify the files by going to the remote host and using cat to view the file for example, such as:
# SSH into the VM and go to the correct path, such as:
cd /home/ubuntu/kubespray
cat ansible.cfg
# Or:
cat inventory/dynamos-cluster/inventory.ini
```

Then you can configure the control plane node:
```sh
# SSH into the control plane node, such as (replace IP of course):
ssh -i ~/.ssh/slice_key -F ssh_config ubuntu@2001:610:2d0:fabc:f816:3eff:fe65:a464
# Go to the kubespray directory, generally:
cd /home/ubuntu/kubespray
# Install dependencies on the VM (only has to be done once)
sudo apt update
# Install pip
sudo apt install -y python3-pip
# Install requirements of kubespray
pip3 install -r requirements.txt
# When asked to restart services just press Enter to restart all of them.

# Export the path to the directory where pip installs it
export PATH=$HOME/.local/bin:$PATH
# Test installation, such as:
ansible version

# Add SSH slice key to connect between the nodes in FABRIC (make sure you followed the SSH config steps from the k8s_setup.ipynb notebook):
mkdir -p ~/.ssh
# Copy the files from your local directory to the remote host, such as (replace IP of course):
./upload_to_remote.sh ~/.ssh/slice_key ubuntu 2001:610:2d0:fabc:f816:3eff:feba:b846 ~/.ssh/slice_key ../fabric_config/ssh_config "~/.ssh"
```