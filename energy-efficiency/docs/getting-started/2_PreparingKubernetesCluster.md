# Preparing Kubernetes cluster
## Linkerd
Extra information: https://linkerd.io/2.15/getting-started/#step-3-install-linkerd-onto-your-cluster

Run these commands individually:
```sh
linkerd install --crds | kubectl apply -f -
# It may take a minute or two for the control plan to finish installing
linkerd install --set proxyInit.runAsRoot=true | kubectl apply -f -
linkerd check
```

## Other
Run these commands individually:
```sh
linkerd jaeger install | kubectl apply -f -
linkerd viz install | kubectl apply -f -
```