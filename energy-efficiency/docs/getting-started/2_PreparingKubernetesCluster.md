# Preparing Kubernetes cluster
Extra information: https://linkerd.io/2.15/getting-started/#step-3-install-linkerd-onto-your-cluster

Run the script file to prepare the kubernetes cluster:
```sh
# Go to the scripts path
cd cd energy-efficiency/scripts/prepare-cluster
# Make the script executable (probably only needs to be done once)
chmod +x linkerd.sh
# Execute the script:
./linkerd.sh 

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

## Further steps: namespaces
Wait for the resources above to be created. You can use:
```sh
linkerd check
```
to see if it is created. This takes a while, so be patient and wait until all is installed.

After everything is created, you can execute the next script:
```sh
# Go to the scripts path
cd cd energy-efficiency/scripts/prepare-cluster
# Make the script executable (probably only needs to be done once)
chmod +x namespaces.sh

# Execute the script with the charts path, such as:
./namespaces.sh /mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/charts
```

## Further steps: api-gateway
Then perform the necessary steps for the api-gateway:
```sh
# Go to the scripts path
cd cd energy-efficiency/scripts/prepare-cluster
# Make the script executable (probably only needs to be done once)
chmod +x api-gateway.sh

# Execute the script with the charts path, such as:
./api-gateway.sh /mnt/c/Users/cpoet/IdeaProjects/EnergyEfficiency_DYNAMOS/charts
```