#!/bin/bash

# This script is a wrapper script that executes every script with a specific set of additions so the script can run in the native noninteractive mode 
# of Jupyter Hub notebooks in FABRIC. Otherwise, the commands cannot be found, such as "helm command not found", etc.
# This script allows to centrally execute the commands and load the necessary information to execute the commands.

# ================================================ 0: Prepare shell environment ================================================
# In this section, the paths are manually exported in the current shell to allow the shell to see it. This might not be necessary with manually SSH into 
# the node, since 

# Add brew to the path, where tools like helm and k9s are installed. Can be retrieved in SSH from the node by executing: which brew
# Then remove the last section, such as /home/linuxbrew/.linuxbrew/bin/brew becomes /home/linuxbrew/.linuxbrew 
# (note that $HOME cannot be used here, that did not work when testing, this might be a different path then /home)
# You can verify that the tools you need for the scripts are present here with for example which helm: /home/linuxbrew/.linuxbrew/bin/helm
export PATH="$PATH:/home/linuxbrew/.linuxbrew/bin"

# ================================================ 1: Execute scripts ================================================
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

echo "DYNAMOS setup complete"
