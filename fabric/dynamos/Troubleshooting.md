# Troubleshooting
This file describes any possible problems that occurred during our setup of DYNAMOS in FABRIC.

See for more information: https://kubernetes.io/docs/tasks/debug/

## DYNAMOS pods stuck in infinite loop of completing, while it should be running
The issue: the DYNAMOS pods were stuck in a loop of creating, running, completed, with Back-off along the way sometimes as well. However, the pods were meant to be running without completing, since it was a deployment (e.g. policy, orchestrator, api-gateway, etc.).

This was likely caused by something in Kubernetes being a bit unstable, which is what we found after checking the nodes:
```sh
ubuntu@k8s-control-plane:~/DYNAMOS/configuration$ kubectl get nodes -o wide
NAME                STATUS     ROLES           AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
dynamos-core        NotReady   <none>          3h20m   v1.31.7   10.145.1.4    <none>        Ubuntu 24.04.1 LTS   6.8.0-49-generic   docker://28.0.4
k8s-control-plane   Ready      control-plane   3h21m   v1.31.7   10.145.1.2    <none>        Ubuntu 24.04.1 LTS   6.8.0-49-generic   docker://28.0.4
surf                Ready      <none>          3h20m   v1.31.7   10.145.1.3    <none>        Ubuntu 24.04.1 LTS   6.8.0-49-generic   docker://28.0.4
uva                 Ready      <none>          3h20m   v1.31.7   10.145.1.4    <none>        Ubuntu 24.04.1 LTS   6.8.0-49-generic   docker://28.0.4
vu                  NotReady   <none>          3h20m   v1.31.7   10.145.1.3    <none>        Ubuntu 24.04.1 LTS   6.8.0-49-generic   docker://28.0.4
```
Two nodes were not ready. You can view the node by:
```sh
# View the nodes with for example:
kubectl describe node dynamos-core
# Here I saw this, meaning it was going to not ready over 96 times over the last 3 hours and 29 minutes. 
Events:
  Type    Reason                   Age                     From             Message
  ----    ------                   ----                    ----             -------
  Normal  NodeHasSufficientMemory  4m32s (x96 over 3h30m)  kubelet          Node dynamos-core status is now: NodeHasSufficientMemory
  Normal  NodeNotReady             3s (x96 over 3h29m)     node-controller  Node dynamos-core status is now: NodeNotReady

# View logs of kubelet:
sudo journalctl -u kubelet -n 100 --no-pager
# In this case there were some errors with the controle plane node connection from the node, such as:
Apr 17 11:30:44 dynamos-core kubelet[6710]: W0417 11:30:44.362586    6710 reflector.go:561] object-"api-gateway"/"rabbit": failed to list *v1.Secret: Get "https://10.145.1.2:6443/api/v1/namespaces/api-gateway/secrets?fieldSelector=metadata.name%3Drabbit&resourceVersion=53720": dial tcp 10.145.1.2:6443: i/o timeout
Apr 17 11:32:26 dynamos-core kubelet[6710]: E0417 11:32:26.629295    6710 controller.go:145] "Failed to ensure lease exists, will retry" err="Get \"https://10.145.1.2:6443/apis/coordination.k8s.io/v1/namespaces/kube-node-lease/leases/dynamos-core?timeout=10s\": net/http: request canceled while waiting for connection (Client.Timeout exceeded while awaiting headers)" interval="400ms"
# Optionally view docker logs:
sudo journalctl -u docker -n 100 --no-pager
```
I saw similar problems with the other nodes. So, this was the underlying problem causing all the issues.

TODO: restart kubernetes cluster setup with k8s_setup.ipynb steps to configure the cluster (reran all steps).

TODO: explain this can be done with similar problems as well.

TODO: remove from archive and add to main, say can also do individual steps.

TODO: otherwise, recreate entire slice.


## gRPC errors/warnings in some pods, such as orchestrator and policy
I encountered these errors/warnings in the logs after running the dynamos-configuration.sh script in the orchestrator and policy pods (I did not check others, but it might also be for others such as api-gateway and uva for example):
```sh
orchestrator 1.7447246019022796e+09    WARN    /app/pkg/lib/go-grpc.go:38    could not check: rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing: dial tcp 127.0.0 ││ .1:50051: connect: connection refused"
```
At first, I thought this was a breaking issue, however, after completing the steps and testing if DYNAMOS works by making requests (see README.md for how to test DYNAMOS), it worked fine and the issue was not showing anymore. So, this issue is fine after startup with dynamos-configuration.sh as long as it is still working, i.e., the pods are running and testing DYNAMOS works successfully. It might be something that is just starting gRPC only when a request is made to DYNAMOS, explaining the error’s existence. For example, the gRPC server startup code or whatever the issue above is might only be started after some things in DYNAMOS are executed, such as a request approval and a data request, since those work fine, and after some time the error was not showing in the logs anymore.


## Pod stuck in infinite Pending state
This issue was that after creating a pod, such as rabbitmq and etcd, it got stuck in Pending. With describe I could see the events:
```sh
kubectl describe pod etcd-0 -n core

# Result example:
Warning  FailedScheduling  4m17s  default-scheduler  0/5 nodes are available: pod has unbound immediate PersistentVolumeClaims. preemption: 0/5 nodes are available: 5 Preemption is not helpful for scheduling
```
This was because there were PVC did not have a PV to bound to, which was created automatically in Docker Desktop local setup, but not here in this case. So, I had to manually add a PV in the yaml charts files. After reapplying it worked. Additional tips:
```sh
# See persistent volume claims (PVC) and their status, such as Pending meaning there is no matching PV, and Bound meaning it is correctly set:
kubectl get pvc -A
# Get PVs:
kubectl get pv -A
```

## Etcd warnings of peer not healthy
On the initial startup of etcd I got the following logs, for example in the etcd-2 pod:
```sh
etcd {"level":"warn","ts":"2025-04-15T13:15:25.869Z","caller":"rafthttp/probing_status.go:68","msg":"prober detected unhealthy status","round-tripper-name":"ROUND_TRIPPER_SNAPSHOT","remote-peer-id":"ce1042 ││ 952548ee4e","rtt":"0s","error":"dial tcp: lookup etcd-1.etcd-headless.core.svc.cluster.local on 10.96.0.10:53: no such host"}
```
However, this was not an issue, this is normal behaviour on startup of etcd, since not all etcd instances are running at the same time. What I did was check if all pods were running, and delete the last etcd replica, such as etcd-2 in k9s, then check the logs again and search for "level":"warn" to see if the same issue was present:
```sh
# Delete the pod in k9s
# Then check logs and wait for it to finish
# Search by pressing / and then paste "level":"warn"
# Verify not the same problem is present
```
This was successful at the time I tried it, so generally, the error can be ignored if these steps are followed and successful.


## ImagePullBackOff/cannot pull images on FABRIC VM
The issue:
```sh
# Running this to get the results:
kubectl describe pod linkerd-destination-77b8ff9d69-l2z4k -n linkerd
# End results:
Events:
  Type     Reason     Age   From               Message
  ----     ------     ----  ----               -------
  Normal   Scheduled  75s   default-scheduler  Successfully assigned linkerd/linkerd-destination-7cb9f86857-zf4dq to dynamos-core
  Normal   Pulled     74s   kubelet            Container image "cr.l5d.io/linkerd/proxy-init:v2.4.2" already present on machine
  Normal   Created    74s   kubelet            Created container: linkerd-init
  Normal   Started    74s   kubelet            Started container linkerd-init
  Normal   Pulling    73s   kubelet            Pulling image "cr.l5d.io/linkerd/proxy:edge-25.4.1"
  Warning  Failed     43s   kubelet            Failed to pull image "cr.l5d.io/linkerd/proxy:edge-25.4.1": Error response from daemon: Get "https://cr.l5d.io/v2/": net/http: TLS handshake timeout
  Warning  Failed     43s   kubelet            Error: ErrImagePull
  Normal   Pulling    43s   kubelet            Pulling image "cr.l5d.io/linkerd/controller:edge-25.4.1"
  Warning  Failed     12s   kubelet            Failed to pull image "cr.l5d.io/linkerd/controller:edge-25.4.1": Error response from daemon: Get "https://cr.l5d.io/v2/": net/http: TLS handshake timeout
  Warning  Failed     12s   kubelet            Error: ErrImagePull
  Normal   BackOff    12s   kubelet            Back-off pulling image "cr.l5d.io/linkerd/controller:edge-25.4.1"
  Warning  Failed     12s   kubelet            Error: ImagePullBackOff
  Normal   Pulling    12s   kubelet            Pulling image "cr.l5d.io/linkerd/policy-controller:edge-25.4.1"
# Main issue:
Failed to pull image "cr.l5d.io/linkerd/controller:edge-25.4.1": Error response from daemon: Get "https://cr.l5d.io/v2/": net/http: TLS handshake timeout
```
This issue seems similar to the issue of no IPv4 access: https://learn.fabric-testbed.net/knowledge-base/using-ipv4-only-resources-like-github-or-docker-hub-from-ipv6-fabric-sites/

However, the solution given on that page does not work in our current setup. Also, it seemed to be specific to this registry: "cr.l5d.io". Since pulling images from docker registry (https://docs.docker.com/reference/cli/docker/image/pull/) and for example GitHub registry (ghcr.io) did work without problems. So, what we did was try to figure out if we could fix it, but this was too specific to FABRIC and therefore likely did not work with that very custom registry. However, we found that we can also pull the docker images from linkerd from their publicly available GitHub registry: https://github.com/orgs/linkerd/packages, which we first tested manually with SSH in the node, such as:
```sh
# Pull same image as problem, but then from public GitHub registry:
sudo docker pull ghcr.io/linkerd/proxy-init:v2.4.2
# Or a different image from the problem:
sudo docker pull ghcr.io/linkerd/proxy:edge-25.4.1
```
And we found that it all worked successfully. 

### Fix 1 (recommended since it requires less custom setup for kubernetes pods of linkerd and other components): Allow IPv4 access from IPv6 only nodes
The solution provided by the documentation from FABRIC described above did not work in our situation. However, there was another place where we did find a solution: https://github.com/teaching-on-testbeds/fabric-education. Specifically: https://github.com/teaching-on-testbeds/fabric-snippets/blob/main/ipv4-access-from-ipv6.md. This repository provided all sorts of helpful things for testbeds, such as FABRIC.

The code added to the notebook:
```py
# enable nodes to access IPv4-only resources, such as Github,
# even if the control interface is IPv6-only
# See: https://github.com/teaching-on-testbeds/fabric-snippets/blob/main/ipv4-access-from-ipv6.md
from ipaddress import ip_address, IPv6Address
for node in slice.get_nodes():
    # Check if the node has IPv6 management IP
    if type(ip_address(node.get_management_ip())) is IPv6Address:
        # Adds a working public IPv6 DNS server (from SURFnet/AMS-IX) to the systemd-resolved config file:
        # 2a00:1098:2c::1 is a known reliable IPv6 DNS resolver.
        node.execute('echo "DNS=2a00:1098:2c::1" | sudo tee -a /etc/systemd/resolved.conf')
        # Restarts the DNS resolver service to apply the new config
        node.execute('sudo service systemd-resolved restart')
        # Adds a loopback entry for the hostname to /etc/hosts
        # Fixes issues where hostname -s cannot resolve to localhost
        # Common workaround for tools like sudo, ssh, or certain init systems that rely on hostname resolution
        node.execute('echo "127.0.0.1 $(hostname -s)" | sudo tee -a /etc/hosts')
        # Replaces /etc/resolv.conf with the systemd-managed symlink
        # On many systems, /etc/resolv.conf is incorrectly set (or overwritten by cloud-init). This command:
        # Deletes any existing file, and recreates it as a symlink to the correct DNS config managed by systemd-resolved
        node.execute('sudo rm -f /etc/resolv.conf; sudo ln -sv /run/systemd/resolve/resolv.conf /etc/resolv.conf')
```
After the execution, the steps for Linkerd were repeated and it worked! See create_slice.ipynb notebook for this, it is added here now in the node configuration.

Explanation:
FABRIC nodes are isolated virtual machines. When you request a slice, each VM (or bare-metal node) gets:
- A management interface (IPv4 or IPv6)
- No NAT
- No internet access unless explicitly configured
Most FABRIC nodes are IPv6-only by default (especially in testbed deployments). Even if the node has IPv4 networking (No working DNS by default):
- /etc/resolv.conf may be empty, misconfigured, or pointing to an unreachable resolver.
- systemd-resolved often fails because no DNS servers are set or /etc/resolv.conf is not correctly linked.

What this fixes is adding a known working IPv6 DNS server: DNS=2a00:1098:2c::1. This is hosted by SURFnet, a European NREN — reliable and often reachable in FABRIC IPv6 networks. It resolves both IPv4 and IPv6 addresses. It also fixes systemd DNS resolution:
- Re-links /etc/resolv.conf to use systemd-resolved's managed output
- Ensures tools like docker, apt, kubectl, etc. can resolve hostnames again

Finally, it fixes problems like "unable to resolve host node1" by adding hostname to /etc/hosts.

Once DNS is working, the node can resolve hostnames like ghcr.io, cr.l5d.io, archive.ubuntu.com, etc. And because most registries resolve to IPv4 addresses, the FABRIC node starts accessing IPv4-based services just fine, even though it's managed over IPv6.

### Fix 2: Customize (less recommended than the previous one)
So, this was the fix to this issue. However, still it needed to be added to the installation of linkerd, which was necessary to use a custom setup with: https://linkerd.io/2.16/tasks/customize-install/.

We followed those steps to run after the installation:
```sh
# Follow install instructions, until:
linkerd install --crds | kubectl apply -f -
# After executing that, now run this (found on: https://linkerd.io/2.16/tasks/customize-install/):
linkerd install \
  --set proxyInit.runAsRoot=true \
  --set nodeSelector."kubernetes\\.io/hostname"=dynamos-core \
  > linkerd.yaml

# Then copy the contents of that file, such as listing it and then manually copying that and pasting it in VSC in linkerd.yaml for example:
cat linkerd.yaml
# In VSC, customize the file, such as searching for the registry "cr.l5d.io" and replacing it with the corresponding images from the public GitHub repository.
# Then upload that file with the script in this project (used throughout the README.md in this folder), such as (replace IP of course in the ssh_config file below if necessary):
./upload_to_remote.sh ../dynamos/linkerd/linkerd.yaml ~/.ssh/slice_key ../fabric_config/ssh_config_upload_script ubuntu dynamos-node "~/DYNAMOS"
./upload_to_remote.sh ../dynamos/linkerd/kustomization.yaml ~/.ssh/slice_key ../fabric_config/ssh_config_upload_script ubuntu dynamos-node "~/DYNAMOS"

# Run again:
# install the Linkerd CRDs
linkerd install --crds | kubectl apply -f -
# install the Linkerd control plane manifests using Kustomize
kubectl kustomize . | kubectl apply -f -
```
Then it worked and the pods were running without the image pull errors.

### Remaining issues/errors
There were two main errors that remained, however, this was the same on the local DYNAMOS setup, so these could be ignored.

Error one in linkerd-destination pod:
```sh
linkerd-proxy [     0.006425s]  WARN ThreadId(01) dst:controller{addr=localhost:8086}:endpoint{addr=127.0.0.1:8086}: linkerd_reconnect: Failed to connect error=endpoint 127.0.0.1:8086: Connection refused ( ││ os error 111) error.sources=[Connection refused (os error 111)]
```
Similar errors where showing in the logs on the local setup of Docker Desktop:
```sh
linkerd-proxy [     5.869205s]  WARN ThreadId(01) dst:controller{addr=localhost:8086}:endpoint{addr=127.0.0.1:8086}: linkerd_reconnect: Failed to connect error=endpoint 127.0.0.1:8086: Connection refused ( ││ os error 111) error.sources=[Connection refused (os error 111)] 

# Also some other minor errors, but the above one was the main one, such as:
policy 2025-04-14T14:36:11.326251Z  INFO httproutes.policy.linkerd.io: kubert::errors: stream failed error=error returned by apiserver during watch: The resourceVersion for the provided watch is too old.:  ││ Expired
```
Therefore, this could be ignored and we could move on to the next step, since the same behaviour was locally, and the pods were still running and nothing was broken.

The second error was with the linkerd-heartbeat pods:
```sh
time="2025-04-14T14:26:10Z" level=error msg="Prometheus query failed: Post \"http://prometheus.linkerd-viz.svc.cluster.local:9090/api/v1/query\": dial tcp: lookup prometheus.linkerd-viz.svc.cluster.local o ││ n 10.96.0.10:53: no such host"
```
But this was likely due to the fact that no linkerd viz installation was made, meaning it was referring to an old setup that did not exist or somehow applied with the main linkerd install, etc. However, it was not used and not necessary, since it is linked to linkerd viz, which we do not use at this time. So, this could be ignored as well at this time. 


## DNS resolution in pods not working, such as raw.githubusercontent.com
The issue: a pod/job could not reach raw.githubusercontent.com:
```sh
curl: (6) Could not resolve host: raw.githubusercontent.com 
``` 
After further checking with:
```sh
# See configmap of the coredns:
kubectl -n kube-system get configmap coredns -o yaml

# Create temp pod with sh:
kubectl run test-pod --rm -it --image=busybox --restart=Never -- sh
# Execute dns lookup, such as well known hosts, the following results were shown:
/ # nslookup raw.githubusercontent.com
Server:         10.96.0.10
Address:        10.96.0.10:53
** server can't find raw.githubusercontent.com: SERVFAIL
** server can't find raw.githubusercontent.com: SERVFAIL
/ # nslookup google.com
Server:         10.96.0.10
Address:        10.96.0.10:53
** server can't find google.com: SERVFAIL
** server can't find google.com: SERVFAIL
```
Furthermore, coredns also gave issues at the time, such as:
```sh
# Note: I lost the specific error, but where the ... is, the ip address was shown
[ERROR] plugin/errors: 2 3471522223707457555.3488489260317122880. HINFO: dial udp [2610:1e0:1700:202::3]:53: connect: network is unreachable
```
This means that the core-dns is likely not working correctly, or there is no correct internet access from the pods.

This was specific to FABRIC, where we we had a FABNetv4, which did not have public internet access. For this we used a workaround to manually add files in the pod, which is not the best solution, but it works. A good solution would be to request FABNetv4Ext access, which does have public internet access, after which this issue will likely solve itself after creating that network for the FABRIC slice. It can then be tested by running the above steps and seeing if the issues are resolved. However, this was not further tested due to time constraints.

### Workaround: manually add files in the nodes
A workaround for this is manually adding the files in the PV's location, since the error here was specifically related to the init-etcd-pvc job trying to access github for some files to add it there:
```sh
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
```