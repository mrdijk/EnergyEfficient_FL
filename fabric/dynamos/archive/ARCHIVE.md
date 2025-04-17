# Archive
This file explains how to setup DYNAMOS in the configured Kubernetes environment in the previous steps for FABRIC.

This guide assumes that you followed the steps in the notebook for each step below.

This is the archived version where everything was working, but with a manual setup, i.e., manually executing everything on the node. The current version is more automated and improved, incorporating most things in the DYNAMOS_setup.ipynb notebook instead of manual steps.


## 1. Install Linkerd
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


## 2. Install DYNAMOS in Kubernetes on the nodes in FABRIC
This installs DYNAMOS by uploading the configuration files and charts to the kubernetes control-plane node.

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
# Then manually start the configuration script.
./dynamos-configuration.sh
# (you can quickly uninstall using the uninstall-dynamos-configuration.sh script):
./uninstall-dynamos-configuration.sh

```
Note: when making changes, the changed files need to be uploaded to the VM again before executing them, such as the dynamos-configuration.sh script and the charts folder.

After that, test DYNAMOS:
```sh
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
# The ingress host under the rule in charts/api-gateway/templates/api-gateway.yaml is api-gateway.api-gateway.svc.cluster.local, so use that as the host, and the path that can be used in the url for the request is "/api/v1" (also from the same yaml file, but then at the path). The url is http, since the ingress specified http.
# In the command below the Host is the ingress rule host for the api-gateway. The url is in the format: http://<NODE-IP>:<INGRESS-CONTROLLER-PORT><API-GATEWAY-RULE-PATH>/<ENDPOINT-FROM-API-GATEWAY>. The rest is just the content body that is passed with the request.
# Then execute the below command to test DYNAMOS (can be on the k8s-controle-plane node, since this is the most logical/best node to run it from because this is the central node for kubernetes and already runs all other scripts).
curl -H "Host: api-gateway.api-gateway.svc.cluster.local" \
  http://10.145.1.6:31924/api/v1/requestApproval \
  -H "Content-Type: application/json" \
  -d '{
    "type": "sqlDataRequest",
    "user": {
        "id": "12324",
        "userName": "jorrit.stutterheim@cloudnation.nl"
    },
    "dataProviders": ["UVA"]
}'
# If it gives back something like this then you are good and DYNAMOS is working:
{
    "authorized_providers": {
        "UVA": "uva.uva.svc.cluster.local"
    },
    "jobId": "jorrit-stutterheim-8e83402f"
}

# Another test: data request, such as from the uva (again run it from the k8s-control-plane node, like explained above):
# The ingress host under the rule in charts/agents/templates/uva.yaml is uva.uva.svc.cluster.local, so use that as the host, and the path that can be used in the url for the request is "/agent/v1/sqlDataRequest/uva" (also from the same yaml file, but then at the path). The url is http, since the ingress specified http.
# The rest follows the same format as the curl command above, but now replaced with these specific values, and including the header for Authorization that is required for this request (now just a placeholder in the current DYNAMOS setup).
# NOTE: do not forget to replace the job-id with the response from the previous curl command.
curl -H "Host: uva.uva.svc.cluster.local" \
  http://10.145.1.6:31924/agent/v1/sqlDataRequest/uva \
  -H "Content-Type: application/json" \
  -H "Authorization: bearer 1234" \
  -d '{
    "type": "sqlDataRequest",
    "query": "SELECT DISTINCT p.Unieknr, p.Geslacht, p.Gebdat, s.Aanst_22, s.Functcat, s.Salschal as Salary FROM Personen p JOIN Aanstellingen s ON p.Unieknr = s.Unieknr LIMIT 30000",
    "algorithm": "",
    "options": {
        "graph": false,
        "aggregate": false
    },
    "user": {
        "id": "12324",
        "userName": "jorrit.stutterheim@cloudnation.nl"
    },
    "requestMetadata": {
        "jobId": "jorrit-stutterheim-8e83402f"
    }
}'
# If it gives back something with data then this is working as well!
# Note: this is the same for other agents, such as vu, and the third party, but then with the values of their respective files.
```

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


## 3. Install monitoring
Note: This guide is used from energy-efficiency/docs/getting-started/3_SetupMonitoring.md, but tailored for the FABRIC setup. Therefore, this guide here will only explain how to execute the script and some specifics for FABRIC, the .md file in the above location gives more information.

Note: kubernetes dashboard is skipped here, since it is not necessary and is not as easy to access because Kubernetes is not running on localhost. Therefore, k9s can be used for this completely.

Run the following:
```sh
# Prometheus stack (includes Grafana with initial setup (e.g. Prometheus as Data source in Grafana, etc.))
# Upload to k8s-control-plane node:
./upload_to_remote.sh ../dynamos/prometheusAndGrafana.sh ~/.ssh/slice_key ../fabric_config/ssh_config_upload_script ubuntu dynamos-node "~/DYNAMOS/configuration"
# Then SSH into the k8s-controle-plane node.
# Go to the DYNAMOS/configuration directory
cd DYNAMOS/configuration
# Then manually start the script
./prometheusAndGrafana.sh
# Wait for it to finish creating, i.e., all pods are running, check with:
kubectl --namespace monitoring get pods -l "release=prometheus"

# Then the next step: Preparing Kepler (energy measurements)
# Upload to k8s-control-plane node:
./upload_to_remote.sh ../dynamos/keplerAndMonitoringChart.sh ~/.ssh/slice_key ../fabric_config/ssh_config_upload_script ubuntu dynamos-node "~/DYNAMOS/configuration"
# Then manually start the script
./keplerAndMonitoringChart.sh
```
For how to add the Kepler dashboard, see energy-efficiency/docs/getting-started/3_SetupMonitoring.md > Preparing Kepler (energy measurements).

Then the checks:
```sh
# First we tried an SSH tunnel with port-forward, but that caused a lot of issues and did not work, such as installing socat, but still it kept giving "socat not found", etc. So, instead of relying on kubectl port-forward, which proxies traffic via the Kubernetes API server and depends on internal tooling (socat), we instead: Exposed Prometheus using a NodePort.
# This is a safe change, it will not break Prometheus or Grafana — as long as the change is only to the Service type, and the underlying pods are running normally. It only adds a NodePort to allow external access outside the kubernetes cluster without affecting the pods of the service, in this case Prometheus.

# So, first SSH into the k8s-control-plane node in a terminal session, like explained in the fabric/k8s/k8s_setup.ipynb notebook and execute the following commands.
# This tells Kubernetes to map Prometheus's internal port (9090) to a static port on the control-plane node itself (e.g., 30906). This allows external access via that high-numbered port — as long as you can reach the node:
kubectl patch svc prometheus-kube-prometheus-prometheus -n monitoring -p '{"spec": {"type": "NodePort"}}'

# To check which external port Prometheus was assigned, run:
kubectl get svc prometheus-kube-prometheus-prometheus -n monitoring
# This can give an output like:
# For example if this is the result of getting the service:
ubuntu@k8s-control-plane:~$ kubectl get svc prometheus-kube-prometheus-prometheus -n monitoring
NAME                                    TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)                         AGE
prometheus-kube-prometheus-prometheus   NodePort   10.111.200.101   <none>        9090:30906/TCP,8080:31028/TCP   14h
# Here 9090:30906/TCP means:
# 9090: the internal port Prometheus listens on inside the Pod/Container, it is defined in the Service spec as the targetPort. This is inside the Kubernetes Pod, not the node itself.
# 30906: the external (NodePort) mapped on the node’s public IP

# Next, on your local machine, go to the path from where you did the SSH connect commands (described in fabric/k8s/k8s_setup.ipynb notebook). Do not yet SSH into the FABRIC node, this below command will do that for you with an SSH tunnel.
# Create an SSH tunnel from your local machine with the NodePort from above, such as (replace with correct IP of the k8s-control-plane node, same as SSH connect command IP):
ssh -i ~/.ssh/slice_key -F ssh_config -L 9090:localhost:30906 ubuntu@2001:610:2d0:fabc:f816:3eff:fea4:5b34
# This creates an SSH tunnel from your local machine to the FABRIC node’s external IP (the same one you normally SSH into), forwarding local port 9090 (on your local machine, i.e. laptop or workstation) to the NodePort 30906. In short it tells SSH: Please take any request to localhost:9090 on my local machine, send it over the SSH tunnel, and on the remote FABRIC node, connect it to localhost:30906 (which is the NodePort of the FABRIC node Prometheus is exposed on).
# Access it at (on your local machine): http://localhost:9090/
# -L 9090:localhost:30906 means: [LOCAL_PORT]:[REMOTE_HOST]:[REMOTE_PORT]
# [LOCAL_PORT]: Listen on local port 9090 on your local machine (e.g., your laptop)
# [REMOTE_HOST]: Tunnel that traffic through the SSH connection. This refers to "localhost" from the perspective of the remote server (in this case, the FABRIC node you're SSH-ing into).
# [REMOTE_PORT]: Forward it to port 30906 on localhost from the perspective of the remote FABRIC node. This is the port on the remote machine (the FABRIC node) that you're connecting to — in this case, the NodePort exposed by Prometheus
```
You can do the same for any other service, such as Grafana. Below are the same commands for Grafana, but then without the above explanation, since it is exactly the same:
```sh
# From SSH in the k8s-control-plane node:
kubectl patch svc prometheus-grafana -n monitoring -p '{"spec": {"type": "NodePort"}}'
kubectl get svc prometheus-grafana -n monitoring
# Example output:
ubuntu@k8s-control-plane:~$ kubectl get svc prometheus-grafana -n monitoring
NAME                 TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
prometheus-grafana   NodePort   10.108.65.229   <none>        80:31092/TCP   15h
# Command with example output for SSH tunnel:
ssh -i ~/.ssh/slice_key -F ssh_config -L 3000:localhost:31092 ubuntu@2001:610:2d0:fabc:f816:3eff:fea4:5b34
# Access it at (on your local machine): http://localhost:3000/
# Login with username: admin
# Get the password:
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

## 4. Load utility functions for further usage of DYNAMOS
This step explains the final step to deploy the utility functions from DYNAMOS on the k8s-control-plane node, so that the kubernetes environment can be easily managed with these functions, etc.:
```sh
# Upload to k8s-control-plane node:
./upload_to_remote.sh ../dynamos/dynamos-configs.sh ~/.ssh/slice_key ../fabric_config/ssh_config_upload_script ubuntu dynamos-node "~/DYNAMOS/configuration"

# SSH into the k8s-control-plane node and go to the corresponding location:
cd DYNAMOS/configuration
# Load the script in the terminal session:
source ./dynamos-configs.sh
# Now you can run functions, such as
deploy_agents
# You need to load the file in the shell each time you restart a shell or when making changing to the dynamos-configs.sh script
```
You can change this file whenever you want, such as adding or removing helpful functions. After changes you have to load it in the shell again each time. Also, for each terminal you have to load the file, so it is recommended to use one terminal to execute those functions when developing.