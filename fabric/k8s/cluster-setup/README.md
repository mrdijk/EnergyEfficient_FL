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
source ./venv/bin/activate
# Then you can execute the following commands:
# TODO: maybe add venv outside of kubespray in the script, so that i can avoid having to rerun that after uploading new kubespray setup

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
Note: do not forget to upload the kubespray changes to the remote host controle plane (in this case node1)! Otherwise, the changes will not apply. For example, reupload the whole kubespray file with several files changed, and only a file when only one file changed, etc.


#### Calico-kube-controllers not working
TODO: now at cannot reach, fix that: TODO: see chatgpt suggestion, already retried with now iptables as kube_proxy_mode
ubuntu@node1:~$ kubectl run testpod --rm -it --restart=Never --image=busybox -- /bin/sh
If you don't see a command prompt, try pressing enter.
/ #
/ # whoami
root
/ # wget --spider https://10.233.0.1:443
Connecting to 10.233.0.1:443 (10.233.0.1:443)
wget: can't connect to remote host (10.233.0.1): No route to host

││ 2025-04-07 10:28:26.127 [ERROR][1] kube-controllers/client.go 320: Error getting cluster information config ClusterInformation="default" error=Get "https://10.233.0.1:443/apis/crd.projectcalico.org/v1/clus ││ terinformations/default": dial tcp 10.233.0.1:443: connect: no route to host                                                                                                                                  ││ 2025-04-07 10:28:26.127 [INFO][1] kube-controllers/client.go 248: Unable to initialize ClusterInformation error=Get "https://10.233.0.1:443/apis/crd.projectcalico.org/v1/clusterinformations/default": dial  ││ tcp 10.233.0.1:443: connect: no route to host                    
kube-system/calico-kube-controllers-74b6df894b-nbws2:calico-kube-controllers
TODO: this did not work:
# Kube-proxy proxyMode configuration.
# Can be ipvs, iptables
# Use iptables for FABRIC specifically
kube_proxy_mode: iptables

```sh
# Run a test pod to execute commands in it in the control plane node (node1)
kubectl run testpod --rm -it --restart=Never --image=busybox -- /bin/sh
# Check if it can reach something
wget --spider https://10.233.0.1:443

# The kube_proxy_mode to iptables was not changing with only running cluster.yml, so I had to do reset.yml and then cluster.yml. Delete and recreate slice and then run every step again, also applied the changes.
# TODO: forgot to upload the kubespray folder, so that is why the changes were not applied. Did need to run reset and then cluster.yml here, but don't know if that works.
# TODO: now should go to ipvs, and then maybe try 24 image?

# TODO: check with below of speciic interface for calico to see if that does something.
# Got:
TASK [network_plugin/calico : Wait for calico kubeconfig to be created] *****************************************************************************************************************************************
fatal: [node2]: FAILED! => {"changed": false, "elapsed": 300, "msg": "Timeout when waiting for file /etc/cni/net.d/calico-kubeconfig"}
fatal: [node3]: FAILED! => {"changed": false, "elapsed": 300, "msg": "Timeout when waiting for file /etc/cni/net.d/calico-kubeconfig"}
# TODO: run again? 
# TODO: now used ipvs as default and using ubuntu 24.

# TODO: add here: kube-proxy running in dual-stack mode is fine, this is also in localhost setup with Kubernetes for DYNAMOS. Also, ipvs is probably also fine, since this is better and more supported, and the default.

# Manual steps to change a config map (not recommended, use the cluster deploy and change variables before running the cluster.yml)
# ConfigMap of pods named kube-proxy
kubectl -n kube-system get configmap kube-proxy -o yaml
# Edit manually:
kubectl -n kube-system edit configmap kube-proxy
# Press i to enter insert mode and make changed. Press Esc to exit instert mode and type :wq and Enter to write (=save) and quit
# Restart pods
kubectl -n kube-system delete pods -l k8s-app=kube-proxy
```
TODO: can use this in k8s-net-calico.yml to ensure it uses the correct one, but not necessary yet:
calico_ip_auto_method: "interface=enp7s0"
TODO: try this when others fail.


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

