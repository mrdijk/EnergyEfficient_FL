# Building DYNAMOS components
Run these commands individually:
```sh
cd go
make agent

# 'make all' will build everything
# 'make proto' will just generate the gRPC files

# Re-deploy by uninstalling agent
helm uninstall agent
helm upgrade -i -f "$agentsValues" agents $agentsPath

# Or just restart the pod:
kubectl rollout restart deployment agent -n agent
```