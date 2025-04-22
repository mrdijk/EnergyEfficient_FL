# Kubernetes Testing
This file explains how Kubernetes cluster tests can be performed, such as performance tests. This is used in my thesis for comparing the local and FABRIC infrastructure setup for Kubernetes to potentially explain any differences.

## General
Additional helpful steps before starting the subsequent steps:
```sh
# SSH commands for the FABRIC commands can be found in fabric/k8s-cluster-setup/k8s_setup.ipynb

# Get the architecture of the current node (used to download a specific binary):
uname -m 
# Or:
uname -m && uname -s
```

## Installing Kube-burner
Kube-burner is used for testing: https://github.com/kube-burner/kube-burner

Installation guide:
```sh
# See releases for available versions and architectures: https://github.com/kube-burner/kube-burner/releases

# With the architecture in mind (see General for which command to use), download the binary, such as:
# Smart trick: open DevTools and download a binary, then check the Network tab for the Headers used, here you can see which URL to use.
curl -Lo kube-burner.tar.gz https://github.com/kube-burner/kube-burner/releases/download/v1.15.1/kube-burner-V1.15.1-linux-x86_64.tar.gz
# Unpack it:
tar -xvzf kube-burner.tar.gz
# Move the executable
chmod +x kube-burner
sudo mv kube-burner /usr/local/bin/
# Verify installation:
kube-burner version
```

## Running workloads
The energy-efficiency/k8s-testing/workloads folder contains the workloads used for testing the kubernetes cluster. 

See for example workloads https://github.com/kube-burner/kube-burner/tree/main/examples/workloads

TODO: explain shortly.

To upload workloads to the FABRIC VMs, see the fabric/scripts/upload_to_remote.sh script. An example can be seen in fabric/dynamos/DYNAMOS_setup.ipynb, where a folder is uploaded to the remote VM in FABRIC. Tip: upload the whole workloads directory to the VM to easily execute several workloads without having to reupload every workload individually.

Now you can run workloads:
```sh
# Go to the root location of a workload, such as:
cd kubelet-density
# The templates folder has to be in the current location, otherwise, it will throw the error "Error reading template templates/pod.yml: failed to open local config file templates/pod.yml: open templates/pod.yml: no such file or directory"

# Then you can execute the workload with kube-burner by specifying the config file, such as:
kube-burner init -c kubelet-density.yml

# Tip: meanwhile, you can view what is happening in the Kubernetes cluster with kubectl commands and k9s for example.
# If something goes wrong, these commands might help to cleanup:
# Remove a selection of pods, such as:
kubectl delete pods -l name=kubelet-density -n kubelet-density

```