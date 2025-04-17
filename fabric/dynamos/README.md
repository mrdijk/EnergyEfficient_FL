# Setup DYNAMOS in Kubernetes
The DYNAMOS_setup.ipynb notebook explained how you can setup DYNAMOS in the FABRIC Kubernetes environment.

This guide assumes that you followed the steps in the notebook for each step below.

Below are some additional helpful things during this process.

## Additional debugging tips
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

## Remaining issues/errors shown
Note: some errors/issues might still be shown in the logs, but this does not break the system and is not necessarily important. For example, the linkerd-heartbeat pods might still show errors, but this can be ignored since we do not use linkerd viz for this setup, likely causing that issue. More issues are described in Troubleshooting.md.