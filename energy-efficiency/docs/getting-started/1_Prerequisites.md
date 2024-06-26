# Preparation (installing prerequisites)
## Install Go
Follow this guide: https://go.dev/dl/. Select the correct OS, for Windows you should download the .msi (Microsoft Installer) file .

## Installing and running Kubernetes
1. Make sure Docker is installed: https://docs.docker.com/desktop/ 

2. Make sure Kubernetes is installed (kubectl and minikube for local development). 

Install minikube (local Kubernetes development): https://minikube.sigs.k8s.io/docs/start/?arch=%2Fwindows%2Fx86-64%2Fstable%2F.exe+download

Install kubectl: https://kubernetes.io/docs/tasks/tools/install-kubectl-windows/

3. Make sure Kubernetes is running:
```sh
minikube start
```
Make sure the Docker engine is running (open Docker Desktop).

## Install Helm (package manager for Kubernetes)
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

## Install Linkerd
1. For Windows you can go to: https://github.com/linkerd/linkerd2/releases and install the .exe for Windows.

2. Then rename the .exe to ‘linkerd’.

3. Then move the .exe to the desired path, such as: C:\linkerd

4. Add to System path environment variables, such as: C:\linkerd

5. Then restart all terminals and verify the installation by running:
```sh
linkerd version
```
