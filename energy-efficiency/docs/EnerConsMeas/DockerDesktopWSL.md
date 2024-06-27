# Docker Desktop usage from wsl

Firstly, make sure Docker Desktop uses WSL2 as the backend: https://docs.docker.com/desktop/wsl/

1. Make sure wsl is opened (run from inside powershell terminal in VSC for example):
```sh
wsl
```

2. Add the user from wsl to the docker group:
```sh
sudo usermod -aG docker $USER
```

3. Restart wsl session:
```sh
# First execute
exit

# Then open wsl again
wsl
```

4. Verify that you can access docker (without sudo before the command)
```sh
docker version
```
It now should print the version, which means that you have access now.