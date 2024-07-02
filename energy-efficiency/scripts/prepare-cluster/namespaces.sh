#!/bin/bash

# Check if an argument was provided
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <chartsPath>"
    exit 1
fi

# First argument is the chartsPath (the path to core folder in DYNAMOS project)
chartsPath="$1"
namespacesChartsPath="$chartsPath/namespaces"
namespacesValues="$namespacesChartsPath/values.yaml"

# Apply/install the namespaces helm release
helm upgrade -i -f "$namespacesValues" namespaces $namespacesChartsPath
