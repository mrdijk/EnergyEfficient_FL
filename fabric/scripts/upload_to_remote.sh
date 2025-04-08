#!/bin/bash

# ============================================
# Script: upload_to_remote.sh
#
# Uploads a local directory or file to a remote VM (e.g., on FABRIC testbed) via SCP.
# - Directories are compressed into a .tar.gz for faster transfer (it is generally much faster to zip a folder and then unzip than upload every file for example)
# - Files are transferred directly
# Supports IPv4, IPv6, and custom SSH config files.
#
# Note: do not forget to specify the REMOTE_DIR when uploading a file to make sure it goes to the correct path on the remote!
# ============================================

# === Input arguments ===
LOCAL_PATH=$1       # Path to local directory or file (e.g., ./kubespray or ./kubespray/dynamos-cluster/inventory.ini)
SSH_KEY=$2          # Path to your SSH private key (e.g., ~/.ssh/slice_key)
SSH_CONFIG=$3       # Path to your custom SSH config (e.g., ./ssh_config)
# These vairables are added at the end (before optional arguments to avoid interference) so they can easily 
# be changed with different users and remote IPs
REMOTE_USER=$4      # Username on the remote node (e.g., ubuntu)
REMOTE_IP=$5        # IP address of the remote node (IPv4 or IPv6 without brackets)
# Optional: remote directory (defaults to ~)
# ~ will automatically resolve to the user's home directory, such as /home/ubuntu
# Use it with "" around the ~ to avoid it already resolving it locally and going to the local machine's home path
REMOTE_DIR="${6:-"~"}"

# === Validation ===
# Ensure exactly 5 or 6 (includes optional arguments) are specified ($0 is the filename)
if [ "$#" -lt 5 ] || [ "$#" -gt 6 ]; then
  echo "Usage ([] means optional): $0 <LOCAL_PATH> <SSH_KEY> <SSH_CONFIG> <REMOTE_USER> <REMOTE_IP> [REMOTE_DIR]"
  echo "Example (directory):       $0 ../kubespray ~/.ssh/slice_key ../fabric_config/ssh_config ubuntu 2001:610:2d0:fabc:f816:3eff:fe03:f07c"
  # Note: "" is used around the REMOTE_DIR here to avoid ~ being resolved to the local user directory, see above explanation for REMOTE_DIR
  echo "Example (file):            $0 ../kubespray/ansible.cfg ~/.ssh/slice_key ../fabric_config/ssh_config ubuntu 2001:610:2d0:fabc:f816:3eff:fe03:f07c \"~/kubespray\""
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

  # Unpack remotely by executing a command on the remote host via ssh
  echo "Extracting '$TAR_NAME' on remote host..."
  ssh -i "$SSH_KEY" -F "$SSH_CONFIG" "$REMOTE_ADDR_SSH" "tar -xzf $TAR_NAME -C $REMOTE_DIR && rm $TAR_NAME"

  # --- Cleanup local tarball ---
  echo "Cleaning up local tarball..."
  rm "$TAR_NAME"

elif [ -f "$LOCAL_PATH" ]; then
  echo "Checking if path '$LOCAL_PATH' exists..."
  ls -la "$LOCAL_PATH"
  # If it's a file, preserve its relative location under kubespray
  FILE_NAME=$(basename "$LOCAL_PATH")

  # Upload the file
  echo "Uploading file '$LOCAL_PATH' to '$REMOTE_ADDR_SCP:$REMOTE_DIR'"
  # Ensure the REMOTE_DIR is only used here so that it does not resolve to the local user's home directory when ~ is used
  scp -i "$SSH_KEY" -F "$SSH_CONFIG" "$LOCAL_PATH" "${REMOTE_ADDR_SCP}:${REMOTE_DIR}/${FILE_NAME}"
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
