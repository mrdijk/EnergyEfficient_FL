#!/bin/bash

# Check if an argument was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <chartsPath>"
    exit 1
fi

# First argument is the chartsPath (the path to charts folder in DYNAMOS project)
chartsPath="$1"

# Deploy orchestrator layer
orchestratorPath="$chartsPath/orchestrator"
orchestratorValues="$orchestratorPath/values.yaml"
# Upgrade or install orchestrator helm release
helm upgrade -i -f "$orchestratorValues" orchestrator $orchestratorPath

# Deploy agents layer
agentsPath="$chartsPath/agents"
agentsValues="$agentsPath/values.yaml"
# Upgrade or install agents helm release
helm upgrade -i -f "$agentsValues" agents $agentsPath

# Deploy third-party layer
thirdPartyPath="$chartsPath/thirdparty"
thirdPartyValues="$thirdPartyPath/values.yaml"
# Upgrade or install third-party helm release
helm upgrade -i -f "$thirdPartyValues" thirdparty $thirdPartyPath