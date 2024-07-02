# Building DYNAMOS components
## Replace Docker Hub account pointing to other use
For the last step to work, make sure that the Makefile in the go and python folder point to your Docker Hub username. Also, in the charts folder, make sure the .yaml files also point to your Docker Hub account, such as charts/agents/templates/uva.yaml.

## Running script
Run these commands individually:
```sh
cd go
make agent

# 'make all' will build everything
# 'make proto' will just generate the gRPC files

# Tutorial to deploy agents specifically (you can do the same for all others, such as orchestrator)
# Create required variables (replace with correct path)
agentsPath="/mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/charts/agents"
orchestratorValues="$orchestratorPath/values.yaml" 
# Re-deploy by uninstalling agent
helm uninstall agent
helm upgrade -i -f "$agentsValues" agents $agentsPath
# Or just restart the pod:
kubectl rollout restart deployment agent -n agent
```