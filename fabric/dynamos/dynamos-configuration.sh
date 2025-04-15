#!/bin/bash

# This is the same configuration script in configuration/dynamos-configuration.sh in this project, but then for FABRIC specifically.

set -e

# Change this to the path of the DYNAMOS repository on your disk
echo "Setting up paths..."
DYNAMOS_ROOT="${HOME}/DYNAMOS"

# Charts
charts_path="${DYNAMOS_ROOT}/charts"
core_chart="${charts_path}/core"
namespace_chart="${charts_path}/namespaces"
orchestrator_chart="${charts_path}/orchestrator"
agents_chart="${charts_path}/agents"
ttp_chart="${charts_path}/thirdparty"
api_gw_chart="${charts_path}/api-gateway"

# Config
config_path="${DYNAMOS_ROOT}/configuration"
k8s_service_files="${config_path}/k8s_service_files"
etcd_launch_files="${config_path}/etcd_launch_files"

rabbit_definitions_file="${k8s_service_files}/definitions.json"
example_definitions_file="${k8s_service_files}/definitions_example.json"

cp "$example_definitions_file" "$rabbit_definitions_file"
echo "definitions_example.json copied over definitions.json to ensure a clean file"

echo "Generating RabbitMQ password..."
# Create a password for a rabbit user
rabbit_pw=$(openssl rand -hex 16)

# Use the RabbitCtl to make a special hash of that password:
hashed_pw=$(sudo docker run --rm rabbitmq:3-management rabbitmqctl hash_password $rabbit_pw)
actual_hash=$(echo "$hashed_pw" | cut -d $'\n' -f2)

echo "Replacing tokens..."
cp ${k8s_service_files}/definitions_example.json ${rabbit_definitions_file}


# The Rabbit Hashed password needs to be in definitions.json file, that is the configuration for RabbitMQ
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS sed
    sed -i '' "s|%PASSWORD%|${actual_hash}|g" ${rabbit_definitions_file}
else
    # GNU sed
    sed -i "s|%PASSWORD%|${actual_hash}|g" ${rabbit_definitions_file}
fi

echo "Installing namespaces..."

# Install namespaces, yaml files that need a specific node have been edited to include that
# (Uninstall with: helm uninstall namespaces)
helm upgrade -i -f ${namespace_chart}/values.yaml namespaces ${namespace_chart} --set secret.password=${rabbit_pw}

echo "Preparing PVC"

{
    cd ${DYNAMOS_ROOT}/configuration
    ./fill-rabbit-pvc.sh
}

# TODO: uncomment below when the above works, doing it step by step.
# TODO: also use the node selector for this like above, this is done in the charts themselves.

# Install nginx, use the dynamos-core node (you can list labels of nodes with: kubectl get nodes --show-labels)
# This expects the nodeSelector to be in the controller section. 
# Here it is explicit in the helm command, since the chart is now not managed in this project
# (Uninstall with: helm uninstall nginx -n ingress)
echo "Installing NGINX..."
helm install -f "${core_chart}/ingress-values.yaml" nginx oci://ghcr.io/nginxinc/charts/nginx-ingress \
    -n ingress --version 0.18.0 \
    --set controller.nodeSelector."kubernetes\\.io/hostname"=dynamos-core

# This again uses the corresponding node by specifying it in the charts folder.
# (Uninstall with: helm uninstall core)
echo "Installing DYNAMOS core..."
helm upgrade -i -f ${core_chart}/values.yaml core ${core_chart} --set hostPath=${HOME} 

# Sleep shortly to make sure the previous one is finished
sleep 5
# Install orchestrator layer
# This again uses the corresponding node by specifying it in the charts folder.
helm upgrade -i -f "${orchestrator_chart}/values.yaml" orchestrator ${orchestrator_chart}

# Sleep shortly to make sure the previous one is finished
sleep 5

# echo "Installing agents layer"
# helm upgrade -i -f "${agents_chart}/values.yaml" agents ${agents_chart}

# sleep 1

# echo "Installing thirdparty layer..."
# helm upgrade -i -f "${ttp_chart}/values.yaml" surf ${ttp_chart}

# sleep 1

# echo "Installing api gateway"
# helm upgrade -i -f "${api_gw_chart}/values.yaml" api-gateway ${api_gw_chart}

echo "Finished setting up DYNAMOS"

exit 0