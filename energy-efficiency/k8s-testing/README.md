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

To upload workloads to the FABRIC VMs, see the fabric/scripts/upload_to_remote.sh script. An example can be seen in fabric/dynamos/DYNAMOS_setup.ipynb, where a folder is uploaded to the remote VM in FABRIC. Tip: upload the whole workloads directory to the VM to easily execute several workloads without having to reupload every workload individually. For example, from the fabric/scripts folder, execute:
```sh
# Make sure the directory exists by executing the following command in SSH on the node:
mkdir -p k8s-testing
# Example execution of the script:
./upload_to_remote.sh ../../energy-efficiency/k8s-testing/workloads ~/.ssh/slice_key ../fabric_config/ssh_config_upload_script ubuntu dynamos-node "~/k8s-testing"
```

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
kubectl delete pods -l kube-burner-job=kubelet-density-heavy -n kube-burner
# Or:
kubectl delete pods -l name=kubelet-density -n kube-burner
# Or delete entire namespace:
kubectl delete ns kube-burner
# Tip: you can view labels in k9s by clicking y on a pod to see the YAML, then you can view the labels Kubernetes attached to the pod.
```

The results will be saved in the specified workload folder, such as workloads/kubelet-density.yml. This can be used to create the results in my thesis.

When done with the results, save them in the data folder for the specific platform, such as local or fabric. Follow the fabric/experiments/experiments.ipynb instructions for how to extract results from the FABRIC VM, such as:
```sh
# Compress the folder on the remote host using SSH (see fabric/k8s/k8s_setup.ipynb for how to connect with SSH and from which local machine location), such as:
# (This uses tar, since that is already present on the ubuntu node). This uses the same config file used in fabric/dynamos/DYNAMOS_setup.ipynb.
# This gets all of the log files in that directory and compresses them
ssh -i ~/.ssh/slice_key -F ssh_config_upload_script dynamos-node \
  "cd ~/k8s-testing/workloads/kubelet-density && tar -czf kubelet-density-logs.tar.gz kube-burner-*.log"

# This copies those files to your local machine:
scp -i ~/.ssh/slice_key -F ssh_config_upload_script \
  dynamos-node:~/k8s-testing/workloads/kubelet-density/kubelet-density-logs.tar.gz .

# Then it should be present, and you move it to your desired location, such as in the correct experiments folder in energy-efficiency/experiments/data-fabric and upload it to GitHub

# Note: this uses the example for kubelet-density, but for other workloads you should change this to their location, such as kubelet-density-heavy
```