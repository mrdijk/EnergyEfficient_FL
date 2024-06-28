# Preparing Kubernetes cluster
Extra information: https://linkerd.io/2.15/getting-started/#step-3-install-linkerd-onto-your-cluster

Run the script file to prepare the kubernetes cluster:
```sh
# Go to the scripts path
cd cd energy-efficiency/scripts/
# Make the script executable
chmod +x prepareKubernetesCluster.sh
# Execute the script:
./prepareKubernetesCluster.sh
 

# "running scripts is disabled on this system" error:
# 1. Close VSC/ 2. Run VSC as administrator / 3. Open powershell terminal (outside wsl) / 4. Run:
Set-ExecutionPolicy RemoteSigned
# 5. Close VSC / 6. Open VSC how you normally do and rerun the script
```
It may take a minute or two for the control plan to finish installing, it generally took about 10 minutes when I tried it.