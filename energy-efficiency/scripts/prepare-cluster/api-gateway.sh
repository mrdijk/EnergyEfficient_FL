#!/bin/bash

# Check if an argument was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <chartsPath>"
    exit 1
fi

# First argument is the chartsPath (the path to core folder in DYNAMOS project)
chartsPath="$1"
apiGatewayChartsPath="$chartsPath/api-gateway"
apiGatewayValues="$apiGatewayChartsPath/values.yaml"

# Apply/install the api-gateway helm release
helm upgrade -i -f "$apiGatewayValues" api-gateway $apiGatewayChartsPath