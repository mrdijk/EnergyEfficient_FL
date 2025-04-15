# Setup Kubernetes
This file explains how to setup DYNAMOS in the configured Kubernetes environment in the previous steps for FABRIC.

This guide assumes that you followed the steps in the notebook for each step below.


## Install Linkerd
Do these steps manually after SSH into the k8s-control-plane node:
```sh
# See: https://linkerd.io/2.17/getting-started/
# Install CLI (using a specific stable version)
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install-edge | LINKERD2_VERSION=edge-25.4.1 sh

# Add Linkerd to PATH
export PATH=$HOME/.linkerd2/bin:$PATH
# Check version to verify installation:
linkerd version

# install the GatewayAPI CRDs (required for linkerd, as output by the command after installing the CLI)
kubectl apply -f https://github.com/kubernetes-sigs/gateway-api/releases/download/v1.2.1/standard-install.yaml

# Validate cluster before installing linkerd:
linkerd check --pre

# Install Linkerd on cluster
# Install Linkerd CRDs
linkerd install --crds | kubectl apply -f -
# Install Linkerd control plane pinned to dynamos-core node (// escapes the .)
# (you can list labels of nodes with: kubectl get nodes --show-labels)
linkerd install \
  --set proxyInit.runAsRoot=true \
  --set nodeSelector."kubernetes\\.io/hostname"=dynamos-core \
  | kubectl apply -f -

# Check cluster
linkerd check

# Install Jaeger onto the cluster for observability
# Install Jaeger on the same node
# This requires a specific setup, see the nodeSelector options in https://github.com/linkerd/linkerd2/blob/main/jaeger/charts/linkerd-jaeger/values.yaml
linkerd jaeger install \
  --set collector.nodeSelector."kubernetes\\.io/hostname"=dynamos-core \
  --set nodeSelector."kubernetes\\.io/hostname"=dynamos-core \
  --set jaeger.nodeSelector."kubernetes\\.io/hostname"=dynamos-core \
  --set webhook.nodeSelector."kubernetes\\.io/hostname"=dynamos-core \
  | kubectl apply -f -

# Optionally install for insight dashboard - not currently in use
# linkerd wiz install | kubectl apply -f -

# Note: you can debug with commands like:
# kubectl describe pod linkerd-destination-77b8ff9d69-l2z4k -n linkerd
# To reset:
# # To remove Linkerd Viz
# linkerd viz uninstall | kubectl delete -f -
# # To remove Linkerd Jaeger
# linkerd jaeger uninstall | kubectl delete -f -
# # Remove control plane:
# linkerd uninstall | kubectl delete -f -
```

TODO: can do with a script later probably if uploading the linkerd.yaml


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
# Upload the charts folder in the DYNAMOS folder, such as (replace IP of course in the ssh_config file below if necessary):
./upload_to_remote.sh ../dynamos/charts ~/.ssh/slice_key ../fabric_config/ssh_config_upload_script ubuntu dynamos-node "~/DYNAMOS"
```
Note: this uses a different ssh_config file specific for the nodes, otherwise, it encountered an error such as "ssh: Could not resolve hostname bastion.fabric-testbed.net: Temporary failure in name resolution". Do not forget to change the IP when new nodes are created in FABRIC.

Then upload the actual files for DYNAMOS in FABRIC specifically:
```sh
# Replace the charts folder in the DYNAMOS folder, such as (replace IP of course in the ssh_config file below if necessary):
./upload_to_remote.sh ../dynamos/charts ~/.ssh/slice_key ../fabric_config/ssh_config_upload_script ubuntu dynamos-node "~/DYNAMOS"

# Replace the congiguration script in this folder with the FABRIC specific configuration script, such as (replace IP of course in the ssh_config file below if necessary):
./upload_to_remote.sh ../dynamos/dynamos-configuration.sh ~/.ssh/slice_key ../fabric_config/ssh_config_upload_script ubuntu dynamos-node "~/DYNAMOS/configuration"
# Optionally add the script for quickly uninstalling for development purposes
./upload_to_remote.sh ../dynamos/uninstall-dynamos-configuration.sh ~/.ssh/slice_key ../fabric_config/ssh_config_upload_script ubuntu dynamos-node "~/DYNAMOS/configuration"

# Workaround for no internet access for etcd init job: manually add the files in the location, see etcd-pvc.yaml:
# SSH into dynamos-core node and create directory:
mkdir -p DYNAMOS
# Upload the configuration folder to the dynamos-core node (after changing the IP in fabric/fabric_config/ssh_config_upload_script temporarily to dynamos-core IP):
./upload_to_remote.sh ../../configuration ~/.ssh/slice_key ../fabric_config/ssh_config_upload_script ubuntu dynamos-node "~/DYNAMOS"
# Then in SSH again, run the following:
sudo mkdir -p /mnt/etcd-data
# Then copy the files to the location of the persistent volume:
sudo cp ~/DYNAMOS/configuration/etcd_launch_files/*.json /mnt/etcd-data
sudo chmod -R 777 /mnt/etcd-data
# Verify files:
ls /mnt/etcd-data
# Then in the ssh_config_upload_script, change back to the IP of the k8s-control-plane node.
# After executing the dynamos-configuration.sh script, you can view the logs of the init-etcd-pvc pod in k9s for example, where you should see something like this for each file:
-rwxrwxrwx    1 root     root          1746 Apr 15 12:00 agreements.json

# SSH into the k8s-control-plane node again.
# Make sure docker is logged in after:
docker login -u poetoec
# Enter the password with a PAT, see https://app.docker.com/settings
# Go to the DYNAMOS/configuration directory
cd DYNAMOS/configuration
# TODO: then manually start the configuration script. Go to the DYNAMOS/configuration folder and execute:
./dynamos-configuration.sh
# (you can quickly uninstall using the uninstall-dynamos-configuration.sh script):
./uninstall-dynamos-configuration.sh

# Test DYNAMOS (without having to add something in the host files, this uses the kubernetes cluster's nodes and setup):
# First list the ingress service:
kubectl get svc -n ingress -A
# Check the api-gateway and nginx-nginx-ingress-controller ones (this one's EXTERNAL-IP is likely still pending, which is fine for FABRIC environment, this is mainly for clouds like AWS). For example:
ubuntu@k8s-control-plane:~/DYNAMOS/configuration$ kubectl get svc -n ingress -A
NAMESPACE        NAME                             TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                                                          AGE
api-gateway      api-gateway                      ClusterIP      10.100.178.113   <none>        8080/TCP                                                         12m
...
default          kubernetes                       ClusterIP      10.96.0.1        <none>        443/TCP                                                          3h9m
ingress          nginx-nginx-ingress-controller   LoadBalancer   10.102.149.144   <pending>     80:31924/TCP,443:31752/TCP                                       12m
# Now you can see that the ingress exposes port 80 through 31924, which you should use as the port
# Now list the nodes to get the NODE-IP:
kubectl get nodes -o wide
# Select the dynamos-core node, such as in this case: 10.145.1.6
ubuntu@k8s-control-plane:~/DYNAMOS/configuration$ kubectl get nodes -o wide
NAME                STATUS   ROLES           AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
dynamos-core        Ready    <none>          3h12m   v1.31.7   10.145.1.6    <none>        Ubuntu 24.04.1 LTS   6.8.0-49-generic   docker://28.0.4
...
# The ingress host under the rule in charts/api-gateway/templates/api-gateway.yaml is api-gateway.api-gateway.svc.cluster.local, so use that as the host, and the path is "/api/v1".
# In the command below the Host is the ingress rule host for the api-gateway. The url is in the format: http://<NODE-IP>:<INGRESS-CONTROLLER-PORT><API-GATEWAY-RULE-PATH>/<ENDPOINT-FROM-API-GATEWAY>. The rest is just the content body that is passed with the request.
# Then execute the below command to test DYNAMOS
curl -H "Host: api-gateway.api-gateway.svc.cluster.local" \
  http://10.145.1.6:31924/api/v1/requestApproval \
  -H "Content-Type: application/json" \
  -d '{
    "type": "sqlDataRequest",
    "user": {
      "id": "12324",
      "userName": "jorrit.stutterheim@cloudnation.nl"
    },
    "dataProviders": ["VU","UVA","RUG"]
}'
# If it gives back something like this then you are good and DYNAMOS is working:
{
    "authorized_providers": {
        "UVA": "uva.uva.svc.cluster.local",
        "VU": "vu.vu.svc.cluster.local"
    },
    "jobId": "jorrit-stutterheim-038fd5ea"
}
```
Note: when making changes, the changed files need to be uploaded to the VM again before executing them, such as the dynamos-configuration.sh script and the charts folder.

Additional tips:
```sh
# Describe pod for debugging, such as finding out why it is stuck in pending (example below, change to desired pod):
kubectl describe pod etcd-0 -n core
# See persistent volume claims (PVC) and their status, such as Pending meaning there is no matching PV, and Bound meaning it is correctly set:
kubectl get pvc -A
# Get PVs:
kubectl get pv -A
# Show labels:
kubectl get nodes --show-labels
kubectl get pods --show-labels -A
# Create debug pod with sh:
kubectl run test-pod --rm -it --image=busybox --restart=Never -- sh
# Get the yaml of a pod:
kubectl get pod api-gateway-6f6fb94f5c-mwzf2 -n api-gateway -o yaml
# Get all ingresses created in the cluster:
kubectl get svc -n ingress -A
```


TODO: further steps after that for energy monitoring, such as Kepler, etc., see energy-efficiency folder