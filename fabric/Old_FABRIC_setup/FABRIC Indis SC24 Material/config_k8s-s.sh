sudo apt update -y
# && sudo apt upgrade -y

# Docker
sudo apt install -y docker.io apt-transport-https curl

# Brew
# sudo apt-get install -y build-essential procps curl file git
# test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
# test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
# echo "eval \"\$($(brew --prefix)/bin/brew shellenv)\"" >> ~/.bashrc

# Kubectl
# brew install kubectl
sudo snap install kubectl --classic
sudo kubectl version

# Helm
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm

# Linkerd
curl --proto '=https' --tlsv1.2 -sSfL https://run.linkerd.io/install-edge | sh
# export PATH=$HOME/.linkerd2/bin:$PATH
export PATH=$PATH:/home/ubuntu/.linkerd2/bin
linkerd install --crds | kubectl apply -f -
linkerd install --set proxyInit.runAsRoot=true | kubectl apply -f -
linkerd check
linkerd jaeger install | kubectl apply -f -
# linkerd wiz install | kubectl apply -f - # Optionally install for insight dashboard - not currently in use