# Preparing Kubernetes cluster
Extra information: https://linkerd.io/2.15/getting-started/#step-3-install-linkerd-onto-your-cluster

Run the script file to prepare the kubernetes cluster:
```sh
# Go to the scripts path
cd cd energy-efficiency/scripts/
# Make the script executable (probably only needs to be done once)
chmod +x prepareKubernetesCluster.sh
# Execute the script:
./prepareKubernetesCluster.sh
 

# "running scripts is disabled on this system" error:
# 1. Close VSC/ 2. Run VSC as administrator / 3. Open powershell terminal (outside wsl) / 4. Run:
Set-ExecutionPolicy RemoteSigned
# 5. Close VSC / 6. Open VSC how you normally do and rerun the script
```
It may take a minute or two for the control plan to finish installing, it generally took about 10 minutes when I tried it.

If you have installed linkerd (see prerequisites) already but it does not recognize it, you can export it again using this command in the terminal:
```sh
export PATH=$HOME/.linkerd2/bin:$PATH
```
This will export it to the current terminal (you may need to repeat this step every time in the terminal when you open a new terminal and you want to use linkerd).