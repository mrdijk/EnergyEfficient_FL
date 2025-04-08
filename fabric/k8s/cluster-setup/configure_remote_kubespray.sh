#!/bin/bash

# This script configures kubespray on the remote host, such as installing a virtual python 
# environment (required for kubespray), and installing dependencies.

set -e  # Exit on any error

# Define the path for the persistent virtual environment
# This creates it oustide of the kubespray directory to avoid it being overridden when new kubespray files are uploaded
# after changes with the upload_to_remote.sh script, removing the venv if it was located inside the kubespray directory.
VENV_PATH="$HOME/kubespray-venv"

# Ensure python3-venv is installed
if ! dpkg -l | grep -q python3-venv; then
    echo "Installing python3-venv package..."
    sudo apt update
    sudo apt install -y python3-venv
fi

# Create the virtual environment if it doesn't already exist
if [ ! -d "$VENV_PATH" ]; then
    echo "Creating virtual environment at $VENV_PATH..."
    python3 -m venv "$VENV_PATH"
fi

# Activate the virtual environment
source "$VENV_PATH/bin/activate"

# Navigate to the kubespray directory
cd kubespray

# Install requirements in the virtual environment
# This cannot be done differently, since it will otherwise error with 
# "error: externally-managed-environment. This environment is externally managed", and ask you to create a venv for it.
pip3 install -r requirements.txt

# Check ansible version to verify installation
ansible --version

echo "Kubespray configuration on control plane successful."