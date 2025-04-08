#!/bin/bash

# This script configures kubespray on the remote host, such as installing a virtual python 
# environment (required for kubespray), and installing dependencies.

set -e  # Exit on any error

# Ensure that you uploaded kubespray to the remote host before executing this script.
# Navigate to the kubespray directory
cd kubespray

# Ensure python3-venv is installed
if ! dpkg -l | grep -q python3-venv; then
    echo "Installing python3-venv package..."
    sudo apt update
    sudo apt install -y python3-venv
fi

# Create and activate virtual python environment
python3 -m venv venv
source ./venv/bin/activate

# Install requirements in the virtual environment
# This cannot be done differently, since it will otherwise error with 
# "error: externally-managed-environment. This environment is externally managed", and ask you to create a venv for it.
pip3 install -r requirements.txt

# Check ansible version to verify installation
ansible --version

echo "Kubespray configuration on control plane successful."