# Getting Started with DYNAMOS
## Preparation (installing prerequisites)
### Installing and running Kubernetes
1. Make sure Docker is installed: https://docs.docker.com/desktop/ 

2. Make sure Kubernetes is installed (kubectl and minikube for local development). 

Install minikube (local Kubernetes development): https://minikube.sigs.k8s.io/docs/start/?arch=%2Fwindows%2Fx86-64%2Fstable%2F.exe+download

Install kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/

3. Make sure Kubernetes is running:
```sh
minikube start
```
Make sure the Docker engine is running (open Docker Desktop).

### Install Helm (package manager for Kubernetes)
Install the package manager for Kubernetes: https://helm.sh/docs/intro/install
It is recommended for Windows to use the binary releases: https://helm.sh/docs/intro/install/#from-the-binary-releases. Steps for binary releases:
1. Download the desired version for the OS, in this case Windows (https://github.com/helm/helm/releases).

2. Unzip.

3. Move the folder to the desired location, such as: C:\helm

4. Add to System path and move it to the top (where the helm application is located), such as:
C:\helm\helm-v3.15.2-windows-amd64\windows-amd64

5. Then restart all terminals and verify the installation by running:
```sh
helm version
```

### Install Linkerd
1. For Windows you can go to: https://github.com/linkerd/linkerd2/releases and install the .exe for Windows.

2. Then rename the .exe to ‘linkerd’.

3. Then move the .exe to the desired path, such as: C:\linkerd

4. Add to System path environment variables, such as: C:\linkerd

5. Then restart all terminals and verify the installation by running:
```sh
linkerd version
```

## Preparing Kubernetes cluster
It is recommended to use the VSC powershell for these commands! You can print variables in powershell by running this command:
```sh
$<variableName>
# e.g. $corePath
```

### Linkerd
Extra information: https://linkerd.io/2.15/getting-started/#step-3-install-linkerd-onto-your-cluster

Run these commands individually:
```sh
linkerd install --crds | kubectl apply -f -
# It may take a minute or two for the control plan to finish installing
linkerd install --set proxyInit.runAsRoot=true | kubectl apply -f -
linkerd check
```

### Other
Run these commands individually:
```sh
linkerd jaeger install | kubectl apply -f -
linkerd viz install | kubectl apply -f -
```


## Preparing rabbitMQ
First, create the namespaces required for all operations:
```sh
# First, create the namespace in the Kubernetes cluster (if not exists)
kubectl create namespace orchestrator; `
kubectl create namespace uva; `
kubectl create namespace vu; `
kubectl create namespace surf; `
kubectl create namespace agents; `
kubectl create namespace ingress; `
kubectl create namespace core
```

Then perform the preparations. Run these commands individually:
```sh
# e.g. $corePath="C:\Users\cpoet\IdeaProjects\EnergyEfficiency_DYNAMOS\charts\core"
$corePath="<path to core in DYNAMOS project>"
$coreValues="$corePath/values.yaml"
helm upgrade -i -f "$coreValues" core $corePath

# Uninstall core (it will fail anyway)
helm uninstall core

# Create password for a rabbit user
# Import System.Web assembly
Add-Type -AssemblyName System.Web
# Generate a random 12-character password
$pw = [System.Web.Security.Membership]::GeneratePassword(12, 1)

# Add password to all namespaces
kubectl create secret generic rabbit --from-literal=password=$pw -n orchestrator
kubectl create secret generic rabbit --from-literal=password=$pw -n uva
kubectl create secret generic rabbit --from-literal=password=$pw -n vu
kubectl create secret generic rabbit --from-literal=password=$pw -n surf

# Hash password
docker run --rm rabbitmq:3-management rabbitmqctl hash_password $pw

# Prepare the definitions.json file
# Rename the file configuration/k8s_service_files/definitions_example.json to definitions.json
# Add hashed password to RabbitMQ definitions.json (above file) for normal_user password_hash

# Install Prometheus
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm upgrade -i -f "$corePath/prometheus-values.yaml" prometheus prometheus-community/prometheus

# Install Nginx
helm install -f "$corePath\ingress-values.yaml" nginx oci://ghcr.io/nginxinc/charts/nginx-ingress -n ingress --version 0.18.0

# Install core
helm upgrade -i -f "$coreValues" core $corePath
```

## Deploying other components
Run the deploy.ps1 (powershell script) file to deploy the components:
```sh
cd <path to deploy.ps1 file>
# e.g. cd .\energy-efficiency\

# Run the file
.\deploy.ps1

# "running scripts is disabled on this system" error:
# 1. Close VSC/ 2. Run VSC as administrator / 3. Open powershell terminal / 4. Run:
Set-ExecutionPolicy RemoteSigned
# 5. Close VSC / 6. Open VSC how you normally do and rerun the script
```


## Building DYNAMOS components