#!/bin/bash

# ================================
# This script uploads your local Kubespray directory 
# to a remote VM (e.g., a FABRIC node) using SCP over SSH.
# Supports both IPv4 and IPv6 addresses.
# ================================

# === Input arguments ===
LOCAL_DIR=$1        # Path to the local Kubespray folder (e.g., ./kubespray)
REMOTE_USER=$2      # SSH user on the remote node (e.g., ubuntu, fedora, root)
REMOTE_IP=$3        # IP address of the remote node (e.g., 10.145.5.2 (=IPv4) or IPv6 address)
SSH_KEY=$4          # Path to the SSH private key used to connect to the remote node
SSH_CONFIG=$5       # Path to ssh_config file

# === Constants ===
# Upload target directory (user's home). Could also be "/home/$REMOTE_USER"
# ~ will always resolve to the correct user's home in Linux/Ubuntu
REMOTE_DIR="~"

# === Validation ===
# Ensure that exactly 5 arguments are provided
if [ "$#" -ne 5 ]; then
  echo "Usage: $0 <LOCAL_DIR> <REMOTE_USER> <REMOTE_IP> <SSH_KEY> <SSH_CONFIG>"
  echo "Example: ./upload_kubespray.sh ../kubespray ubuntu 2001:610:2d0:fabc:f816:3eff:feba:b846 ~/.ssh/slice_key ../fabric_config/ssh_config"
  exit 1
fi

# === IPv6 Bracket Handling ===
# If the IP contains a colon, assume it's IPv6 and enclose in brackets
if [[ "$REMOTE_IP" == *:* ]]; then
  FORMATTED_IP="[$REMOTE_IP]"
else
  FORMATTED_IP="$REMOTE_IP"
fi

# Build remote address
REMOTE_ADDR="${REMOTE_USER}@${FORMATTED_IP}"

# === Upload with SCP ===
# Use scp to recursively upload the local directory to the remote home directory
# Use the provided SSH key and custom SSH config file
echo "Uploading '$LOCAL_DIR' to '$REMOTE_ADDR:$REMOTE_DIR' using key '$SSH_KEY' and config '$SSH_CONFIG'"
scp -i "$SSH_KEY" -F "$SSH_CONFIG" -r "$LOCAL_DIR" "${REMOTE_ADDR}:${REMOTE_DIR}"

# === Result check ===
# $? is the exit status of the previous command: 0 = success, non-zero = failure
if [ $? -eq 0 ]; then
  echo "Upload complete!"
else
  echo "Upload failed."
fi
