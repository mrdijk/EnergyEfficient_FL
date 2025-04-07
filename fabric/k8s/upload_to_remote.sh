#!/bin/bash

# ============================================
# Script: upload_to_remote.sh
#
# Uploads a local directory or file to a remote VM (e.g., on FABRIC testbed) via SCP.
# - Directories are compressed into a .tar.gz for faster transfer (it is generally much faster to zip a folder and then unzip than upload every file for example)
# - Files are transferred directly
# Supports IPv4, IPv6, and custom SSH config files.
#
# Note: the local path is where the file will be uploaded on the remote VM, so this must correspond to an already existing file
# ============================================

# === Input arguments ===
LOCAL_PATH=$1       # Path to local directory or file (e.g., ./kubespray or ./kubespray/dynamos-cluster/inventory.ini)
REMOTE_USER=$2      # Username on the remote node (e.g., ubuntu)
REMOTE_IP=$3        # IP address of the remote node (IPv4 or IPv6 without brackets)
SSH_KEY=$4          # Path to your SSH private key (e.g., ~/.ssh/slice_key)
SSH_CONFIG=$5       # Path to your custom SSH config (e.g., ./ssh_config)

# === Constants ===
# Upload destination — the user's home directory on the remote machine
# ~ will automatically resolve to the user's home directory, such as /home/ubuntu
REMOTE_DIR="~"

# === Validation ===
# Ensure the correct number of arguments is provided
if [ "$#" -ne 5 ]; then
  echo "Usage: $0 <LOCAL_PATH> <REMOTE_USER> <REMOTE_IP> <SSH_KEY> <SSH_CONFIG>"
  echo "Example (directory): ./upload_to_remote.sh ./kubespray ubuntu 10.145.5.2 ~/.ssh/slice_key ./ssh_config"
  echo "Example (file):      ./upload_to_remote.sh ./kubespray/dynamos-cluster/inventory.ini ubuntu <ip> <key> <config>"
  exit 1
fi

# === IPv6 Address Formatting ===
# Create separate SSH/SCP-friendly addresses
# SCP requires IPv6 addresses to be wrapped in square brackets, but SSH does not
if [[ "$REMOTE_IP" == *:* ]]; then
  # IPv6
  REMOTE_ADDR_SCP="${REMOTE_USER}@[${REMOTE_IP}]"
  REMOTE_ADDR_SSH="${REMOTE_USER}@${REMOTE_IP}"
else
  # IPv4
  REMOTE_ADDR_SCP="${REMOTE_USER}@${REMOTE_IP}"
  REMOTE_ADDR_SSH="${REMOTE_USER}@${REMOTE_IP}"
fi

# Combine remote user and IP into an SCP-compatible address
REMOTE_ADDR="${REMOTE_USER}@${FORMATTED_IP}"

# === Upload logic ===
if [ -d "$LOCAL_PATH" ]; then
  # --- Compress directory for faster file uploads (especially for directories with many small files) ---
  DIR_NAME=$(basename "$LOCAL_PATH")
  TAR_NAME="${DIR_NAME}.tar.gz"
  echo "Compressing directory '$LOCAL_PATH' into '$TAR_NAME'..."
  tar -czf "$TAR_NAME" -C "$(dirname "$LOCAL_PATH")" "$DIR_NAME"

  # Upload the tarball
  echo "Uploading '$TAR_NAME' to '$REMOTE_ADDR_SCP:$REMOTE_DIR'"
  scp -i "$SSH_KEY" -F "$SSH_CONFIG" "$TAR_NAME" "${REMOTE_ADDR_SCP}:${REMOTE_DIR}"

  # Unpack remotely
  echo "Extracting '$TAR_NAME' on remote host..."
  ssh -i "$SSH_KEY" -F "$SSH_CONFIG" "$REMOTE_ADDR_SSH" "tar -xzf $TAR_NAME -C $REMOTE_DIR && rm $TAR_NAME"

  # --- Cleanup local tarball ---
  echo "Cleaning up local tarball..."
  rm "$TAR_NAME"

elif [ -f "$LOCAL_PATH" ]; then
  # --- Upload file directly ---
  echo "Uploading file '$LOCAL_PATH' to '$REMOTE_ADDR:$REMOTE_DIR'"
  scp -i "$SSH_KEY" -F "$SSH_CONFIG" "$LOCAL_PATH" "${REMOTE_ADDR}:${REMOTE_DIR}"
else
  echo "Error: '$LOCAL_PATH' is not a valid file or directory."
  exit 1
fi

# === Final result ===
# $? is the exit code of the last command: 0 = success, non-zero = error
if [ $? -eq 0 ]; then
  echo "Upload complete!"
else
  echo "Upload failed."
fi
