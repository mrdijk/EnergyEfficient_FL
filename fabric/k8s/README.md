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
# --private-key=<path-to-private-key> is not necessary here as it will override the ssh_config used in ansible.cfg, which is not what we want
# TODO: update documentation here
# Use username ubuntu (-u), this is the same as the local ssh command used to log into the VM
ansible-playbook -i inventory/dynamos-cluster/inventory.ini cluster.yml -b -v --private-key=~/.ssh/slice_key -u ubuntu
# TODO: now the connection works and the cluster.yml is executing, still need to test if it now does everything correctly after executing
# TODO: then run next step to check the nodes with the script

TODO: Update: now used ip address with local SSH and that also times out and does not work. So, now tried to mimic SSH command with IPv6 for ansible_host, such as:
node1 ansible_host=2001:610:2d0:fabc:f816:3eff:fe65:a464 ip=10.30.6.111 etcd_member_name=etcd1
TODO: Did get these fatal errors in the process, but it continued, might not be that important:
# TASK [kubernetes/node : Modprobe conntrack module] ******************************************************************************************************************************************
# changed: [node3] => (item=nf_conntrack) => {"ansible_loop_var": "item", "changed": true, "item": "nf_conntrack", "name": "nf_conntrack", "params": "", "state": "present"}
# fatal: [node3]: FAILED! => {"msg": "The conditional check '(modprobe_conntrack_module|default({'rc': 1})).rc != 0' failed. The error was: error while evaluating conditional ((modprobe_conntrack_module|default({'rc': 1})).rc != 0): 'dict object' has no attribute 'rc'. 'dict object' has no attribute 'rc'\n\nThe error appears to be in '/mnt/c/Users/cpoet/VSC_Projs/EnergyEfficiency_DYNAMOS/fabric/kubespray/roles/kubernetes/node/tasks/main.yml': line 121, column 3, but may\nbe elsewhere in the file depending on the exact syntax problem.\n\nThe offending line appears to be:\n\n\n- name: Modprobe conntrack module\n  ^ here\n"}
# ...ignoring
# changed: [node2] => (item=nf_conntrack) => {"ansible_loop_var": "item", "changed": true, "item": "nf_conntrack", "name": "nf_conntrack", "params": "", "state": "present"}
# fatal: [node2]: FAILED! => {"msg": "The conditional check '(modprobe_conntrack_module|default({'rc': 1})).rc != 0' failed. The error was: error while evaluating conditional ((modprobe_conntrack_module|default({'rc': 1})).rc != 0): 'dict object' has no attribute 'rc'. 'dict object' has no attribute 'rc'\n\nThe error appears to be in '/mnt/c/Users/cpoet/VSC_Projs/EnergyEfficiency_DYNAMOS/fabric/kubespray/roles/kubernetes/node/tasks/main.yml': line 121, column 3, but may\nbe elsewhere in the file depending on the exact syntax problem.\n\nThe offending line appears to be:\n\n\n- name: Modprobe conntrack module\n  ^ here\n"}
# ...ignoring
# changed: [node1] => (item=nf_conntrack) => {"ansible_loop_var": "item", "changed": true, "item": "nf_conntrack", "name": "nf_conntrack", "params": "", "state": "present"}
# fatal: [node1]: FAILED! => {"msg": "The conditional check '(modprobe_conntrack_module|default({'rc': 1})).rc != 0' failed. The error was: error while evaluating conditional ((modprobe_conntrack_module|default({'rc': 1})).rc != 0): 'dict object' has no attribute 'rc'. 'dict object' has no attribute 'rc'\n\nThe error appears to be in '/mnt/c/Users/cpoet/VSC_Projs/EnergyEfficiency_DYNAMOS/fabric/kubespray/roles/kubernetes/node/tasks/main.yml': line 121, column 3, but may\nbe elsewhere in the file depending on the exact syntax problem.\n\nThe offending line appears to be:\n\n\n- name: Modprobe conntrack module\n  ^ here\n"}
# ...ignoring

# Another one:
# TASK [kubernetes/control-plane : Check which kube-control nodes are already members of the cluster] *****************************************************************************************
# fatal: [node1]: FAILED! => {"changed": false, "cmd": ["/usr/local/bin/kubectl", "get", "nodes", "--selector=node-role.kubernetes.io/control-plane", "-o", "json"], "delta": "0:00:00.037381", "end": "2025-04-04 08:05:42.432051", "msg": "non-zero return code", "rc": 1, "start": "2025-04-04 08:05:42.394670", "stderr": "E0404 08:05:42.423966   35848 memcache.go:265] \"Unhandled Error\" err=\"couldn't get current server API group list: Get \\\"http://localhost:8080/api?timeout=32s\\\": dial tcp 127.0.0.1:8080: connect: connection refused\"\nE0404 08:05:42.425474   35848 memcache.go:265] \"Unhandled Error\" err=\"couldn't get current server API group list: Get \\\"http://localhost:8080/api?timeout=32s\\\": dial tcp 127.0.0.1:8080: connect: connection refused\"\nE0404 08:05:42.427228   35848 memcache.go:265] \"Unhandled Error\" err=\"couldn't get current server API group list: Get \\\"http://localhost:8080/api?timeout=32s\\\": dial tcp 127.0.0.1:8080: connect: connection refused\"\nE0404 08:05:42.428434   35848 memcache.go:265] \"Unhandled Error\" err=\"couldn't get current server API group list: Get \\\"http://localhost:8080/api?timeout=32s\\\": dial tcp 127.0.0.1:8080: connect: connection refused\"\nE0404 08:05:42.429604   35848 memcache.go:265] \"Unhandled Error\" err=\"couldn't get current server API group list: Get \\\"http://localhost:8080/api?timeout=32s\\\": dial tcp 127.0.0.1:8080: connect: connection refused\"\nThe connection to the server localhost:8080 was refused - did you specify the right host or port?", "stderr_lines": ["E0404 08:05:42.423966   35848 memcache.go:265] \"Unhandled Error\" err=\"couldn't get current server API group list: Get \\\"http://localhost:8080/api?timeout=32s\\\": dial tcp 127.0.0.1:8080: connect: connection refused\"", "E0404 08:05:42.425474   35848 memcache.go:265] \"Unhandled Error\" err=\"couldn't get current server API group list: Get \\\"http://localhost:8080/api?timeout=32s\\\": dial tcp 127.0.0.1:8080: connect: connection refused\"", "E0404 08:05:42.427228   35848 memcache.go:265] \"Unhandled Error\" err=\"couldn't get current server API group list: Get \\\"http://localhost:8080/api?timeout=32s\\\": dial tcp 127.0.0.1:8080: connect: connection refused\"", "E0404 08:05:42.428434   35848 memcache.go:265] \"Unhandled Error\" err=\"couldn't get current server API group list: Get \\\"http://localhost:8080/api?timeout=32s\\\": dial tcp 127.0.0.1:8080: connect: connection refused\"", "E0404 08:05:42.429604   35848 memcache.go:265] \"Unhandled Error\" err=\"couldn't get current server API group list: Get \\\"http://localhost:8080/api?timeout=32s\\\": dial tcp 127.0.0.1:8080: connect: connection refused\"", "The connection to the server localhost:8080 was refused - did you specify the right host or port?"], "stdout": "", "stdout_lines": []}
# ...ignoring

# Another one:
# TASK [kubernetes/kubeadm : Join to cluster if needed] ***************************************************************************************************************************************
# fatal: [node2]: FAILED! => {"changed": true, "cmd": ["timeout", "-k", "120s", "120s", "/usr/local/bin/kubeadm", "join", "--config", "/etc/kubernetes/kubeadm-client.conf", "--ignore-preflight-errors=DirAvailable--etc-kubernetes-manifests", "--skip-phases="], "delta": "0:01:00.063023", "end": "2025-04-04 08:08:20.938515", "msg": "non-zero return code", "rc": 1, "start": "2025-04-04 08:07:20.875492", "stderr": "error execution phase preflight: couldn't validate the identity of the API Server: failed to request the cluster-info ConfigMap: Get \"https://10.30.6.111:6443/api/v1/namespaces/kube-public/configmaps/cluster-info?timeout=10s\": context deadline exceeded\nTo see the stack trace of this error execute with --v=5 or higher", "stderr_lines": ["error execution phase preflight: couldn't validate the identity of the API Server: failed to request the cluster-info ConfigMap: Get \"https://10.30.6.111:6443/api/v1/namespaces/kube-public/configmaps/cluster-info?timeout=10s\": context deadline exceeded", "To see the stack trace of this error execute with --v=5 or higher"], "stdout": "[preflight] Running pre-flight checks", "stdout_lines": ["[preflight] Running pre-flight checks"]}
# fatal: [node3]: FAILED! => {"changed": true, "cmd": ["timeout", "-k", "120s", "120s", "/usr/local/bin/kubeadm", "join", "--config", "/etc/kubernetes/kubeadm-client.conf", "--ignore-preflight-errors=DirAvailable--etc-kubernetes-manifests", "--skip-phases="], "delta": "0:01:00.063133", "end": "2025-04-04 08:08:20.958289", "msg": "non-zero return code", "rc": 1, "start": "2025-04-04 08:07:20.895156", "stderr": "error execution phase preflight: couldn't validate the identity of the API Server: failed to request the cluster-info ConfigMap: Get \"https://10.30.6.111:6443/api/v1/namespaces/kube-public/configmaps/cluster-info?timeout=10s\": context deadline exceeded\nTo see the stack trace of this error execute with --v=5 or higher", "stderr_lines": ["error execution phase preflight: couldn't validate the identity of the API Server: failed to request the cluster-info ConfigMap: Get \"https://10.30.6.111:6443/api/v1/namespaces/kube-public/configmaps/cluster-info?timeout=10s\": context deadline exceeded", "To see the stack trace of this error execute with --v=5 or higher"], "stdout": "[preflight] Running pre-flight checks", "stdout_lines": ["[preflight] Running pre-flight checks"]}
```
