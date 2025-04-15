# Troubleshooting
This file describes any possible problems that occurred during our setup of DYNAMOS in FABRIC.

See for more information: https://kubernetes.io/docs/tasks/debug/


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

TODO: explain if it worked after creating nodes with IPv4 access (solution for previous one), and only after that configuring the kubernetes cluster. Before I did it while the kubernetes cluster was already created, and it might be that the host file was inherited from the node at that time when the setup was not yet done, causing the issues above.
TODO: new: that also did not fix the issue. Now requested FABNetv4Ext