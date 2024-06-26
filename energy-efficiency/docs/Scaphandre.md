# Scaphandre in DYNAMOS

# TODO: if it is not possible for some reason to use Scaphandre, a backup could be Kernel: https://sustainable-computing.io/

## Preparing minikube Kubernetes cluster
```sh
# Make sure minikube is running (minikube start). In this project we use Docker for the containers/VMs

# Open the SSH in minikube to access the minikube VM
minikube ssh

# Kernel setup:
# Install prometheus stack (assuming prometheus has been installed (see step 3: PreparingRabbitMQ))
helm install prometheus prometheus-community/kube-prometheus-stack --namespace monitoring --create-namespace --wait
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