# Energy Consumption Measurements in DYNAMOS

# TODO: if it is not possible for some reason to use Scaphandre, a backup could be Kernel: https://sustainable-computing.io/
Probably NOT possible, since:
![alt text](./assets/ScaphandreMinikubePowercapError.png)

This is because powercap is not visible and does not exist:
![alt text](./assets/MinikubeSSHPowercapNotExists.png)

Therefore, it is unfortunately not possible to use Scaphandre in the current setup. This is probably due to the fact that Scaphandre is only run on physical machines and running Kubernetes using minikube with the Docker engine is creating a Virtual Machine (VM) environment. Therefore, an alternative is considered: Kubernetes Efficient Power Level Exporter (Kepler). This is a Prometheus exporter that is specialized for Kubernetes.
# TODO: add in master thesis when Kernel is working. With above explanation and add short explanation on Kernel using the documentation as a reference!

## Preparing minikube Kubernetes cluster
```sh
# Make sure minikube is running (minikube start). In this project we use Docker for the containers/VMs

# Open the SSH in minikube to access the minikube VM
minikube ssh

# Kernel setup:
# Install prometheus (already done in step 3 of getting started, but to make sure do it again)
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
# Install prometheus stack
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace --wait

# Add Kepler
helm repo add kepler https://sustainable-computing-io.github.io/kepler-helm-chart
helm repo update
helm search repo kepler
# Install Kepler
helm install kepler kepler/kepler --namespace kepler --create-namespace --set serviceMonitor.enabled=true --set serviceMonitor.labels.release=prometheus 
# After this final installation you should be able to view the Kepler namespace in minikube dashboard
```

## Installing scaphandre in Kubernetes cluster
```sh
# Create a new folder/project and open it in VSC.

# Clone the git repository in the new project
git clone https://github.com/hubblo-org/scaphandre

# Go to the scaphandre folder
cd scaphandre

# Install scaphandre in the Kubernetes cluster using helm
helm install scaphandre helm/scaphandre --namespace monitoring
# Or: move the scaphandre folder into the charts folder and then run
helm install scaphandre --namespace monitoring

# Verify installation
helm list
```

# TODO: above not working due to 'powercap' . See this, maybe it helps: https://www.scaleway.com/en/blog/how-to-measure-energy-consumption-applications-kubernetes/

TODO: prometheus-values.yaml file needs to be configured to add scaphandre?
C:\Users\cpoet\IdeaProjects\EnergyEfficiency_DYNAMOS\charts\core\prometheus-values.yaml
Add this?
```yaml
- job_name: 'scaphandre'
    scrape_interval: 10s
    kubernetes_sd_configs:
    - role: endpoints
      namespaces:
        names:
        - monitoring
    relabel_configs:
    - source_labels: [__meta_kubernetes_service_label_app]
      action: keep
      regex: scaphandre
```
# TODO: add documentation on how I added Scaphandre to DYNAMOS in Prometheus.