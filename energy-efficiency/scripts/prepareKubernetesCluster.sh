#!/bin/bash

# Install linkerd
linkerd install --crds | kubectl apply -f -
# It may take a minute or two for the control plan to finish installing
linkerd install --set proxyInit.runAsRoot=true | kubectl apply -f -
linkerd check

# Install jaegar
linkerd jaeger install | kubectl apply -f -
# Optional command:
# linkerd viz install | kubectl apply -f -