# Preparing rabbitMQ
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
# Install in monitoring namespace
helm upgrade -i -f "$corePath/prometheus-values.yaml" prometheus prometheus-community/prometheus

# Install Nginx
helm install -f "$corePath\ingress-values.yaml" nginx oci://ghcr.io/nginxinc/charts/nginx-ingress -n ingress --version 0.18.0

# Install core
helm upgrade -i -f "$coreValues" core $corePath
```