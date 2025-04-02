#!/bin/bash

# This script prepares kubespray by cloning the code and then removing unnecessary files so that this can be added in 
# the current repository and configured for further usage, etc.

set -e  # Exit on any error

# Step 1: Clone Kubespray
git clone https://github.com/kubernetes-sigs/kubespray.git
# Go to fabric/kubespray (assuming the script is executed from the fabric directory)
cd kubespray

# Step 2: Checkout a stable release branch specific version
# (this checks out the branch of kubespray called release-x)
git checkout release-2.27

# Step 3: Install Python dependencies (installs Ansible, etc.)
pip3 install -r requirements.txt

# Step 4: Clean up unnecessary files (-rf is -r for recursive to delete folders and -f to force delete)
rm -rf .git # Git file with a lot of Git related files that are not necessary
rm -rf docs # Docs is not necessary, can be viewed here: https://github.com/kubernetes-sigs/kubespray
rm -rf .github .gitlab-ci # Git related files such as workflows, etc. not necessary 
rm -rf contrib # Contributing not necessary
rm -rf logo # Logo images not necessary
rm -rf scripts # Scripts not necessary
rm -rf test-infra tests # Tests not necessary
# Delete specific files that are not necessary
# Git specific files
rm -f .gitattributes .gitignore .gitlab-ci.yml .gitmodules .pre-commit-config.yaml
# License and other docs files not necessary
rm -f CHANGELOG.MD code-of-conduct.md CONTRIBUTING.md OWNERS OWNERS_ALIASES README.md RELEASE.MD LICENSE SECURITY_CONTACTS
# Other files
rm -f index.html

echo "Kubespray prepared and cleaned. Now you can configure it and use it to manage and configure the Kubernetes cluster."
