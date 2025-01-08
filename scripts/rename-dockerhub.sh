#!/bin/bash

# Define your personal and organizational account names
PERSONAL_ACCOUNT="dynamos1"
ORG_ACCOUNT="poetoec"

# Define a dictionary mapping old repository names to new repository names
declare -A IMAGE_MAP=(
    # SQL Services
    ["sql-aggregate:latest"]="sql-aggregate:latest"
    ["sql-algorithm:latest"]="sql-algorithm:latest"
    ["sql-anonymize:latest"]="sql-anonymize:latest"
    ["sql-query:latest"]="sql-query:latest"
    ["sql-test:latest"]="sql-test:latest"

    # Federated Learning Services
    # ["fl-aggregate:latest"]="fl-aggregate:latest"
    # ["fl-evaluate-service:latest"]="fl-evaluate-service:latest"
    # ["fl-federated-learning:latest"]="fl-federated-learning:latest"
    # ["fl-model-service:latest"]="fl-model-service:latest"

    # Core Services
    ["agent:latest"]="agent:latest"
    ["api-gateway:latest"]="api-gateway:latest"
    ["orchestrator:latest"]="orchestrator:latest"
    ["policy-enforcer:latest"]="policy-enforcer:latest"
    ["sidecar:latest"]="sidecar:latest"

    # Test Services
    ["test:latest"]="test:latest"
    ["new-service:latest"]="new-service:latest"
)

# Loop through each image in the dictionary
for OLD_IMAGE in "${!IMAGE_MAP[@]}"; do
    docker pull ${PERSONAL_ACCOUNT}/${OLD_IMAGE}
    NEW_IMAGE=${IMAGE_MAP[$OLD_IMAGE]}

    # Tag the image with the new organizational account name and new repository name
    docker tag ${PERSONAL_ACCOUNT}/${OLD_IMAGE} ${ORG_ACCOUNT}/${NEW_IMAGE}

    # Push the image to the organizational account with the new repository name
    docker push ${ORG_ACCOUNT}/${NEW_IMAGE}

    # Optionally, remove the old image from the personal account
    # docker rmi ${PERSONAL_ACCOUNT}/${OLD_IMAGE}
done
