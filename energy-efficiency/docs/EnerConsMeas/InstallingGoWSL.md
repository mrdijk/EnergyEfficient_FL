# Install Go
1. Check the latest go version: https://go.dev/dl/

2. Execute these commands individually:
```sh
# Install Go
# e.g. wget https://dl.google.com/go/go1.22.4.linux-amd64.tar.gz
wget https://dl.google.com/go/<version>.linux-amd64.tar.gz
# e.g. sudo tar -xvf go1.22.4.linux-amd64.tar.gz
sudo tar -xvf <version>.linux-amd64.tar.gz
sudo mv go /usr/local

# Open .bashrc file
cd ~
explorer.exe .

# Add following lines at the bottom and save the file.
export GOROOT=/usr/local/go
export GOPATH=$HOME/go
export PATH=$GOPATH/bin:$GOROOT/bin:$PATH

# Refresh terminal
exit
# Reopen terminal
wsl
# Check go version to verify installation
go version

# Then you can remove the downloaded tar file from step 1 if you want, this is not required anymore after unpacking it.
```