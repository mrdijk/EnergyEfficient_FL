#!/bin/bash

# This script is a wrapper script that executes all the sub scripts at the same time

# Go to the location where the scripts are located:
cd DYNAMOS/configuration

# Setup linkerd
./linkerd.sh
# Wait shortly in between scripts to make sure everything is stable again
echo "Waiting shortly for everything to stabilize..."
sleep 10

# Setup DYNAMOS
./dynamos-configuration.sh
# Wait shortly in between scripts to make sure everything is stable again
echo "Waiting shortly for everything to stabilize..."
# Wait longer after DYNAMOS setup before monitoring to make sure everything has started
sleep 45

# Setup monitoring
./monitoring.sh

echo "Full DYNAMOS setup complete"
