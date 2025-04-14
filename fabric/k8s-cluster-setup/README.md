# Setup Kubernetes
This file explains how to setup Kubernetes in FABRIC.

Note: this guide used WSL for the underlying testing and validation.

Below are some additional things that might be helpful. Most documentation is made inside the files itself, such as the scripts to configure the kubernetes cluster.

Currently, we use Kubeadm for the cluster setup, however, before we tried kubespray, which is present in the archive folder with an explanation of why we switched.

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

### Troubleshooting
See the Troubleshooting.md file.
