# Configure cgroupv2 with WSL and Docker

Firstly, make sure Docker Desktop uses WSL2 as the backend: https://docs.docker.com/desktop/wsl/

## Create .wslconfig file
1. In VSC create a new file called .wslconfig

2. Add the following content
```
[wsl2]
kernelCommandLine = cgroup_no_v1=all
```
This file will contain global configurations for WSL2.

3. Move this file to the UserProfile location. This is usually: C:\Users\<UserName>

The easiest way is to open Windows file explorer and enter %UserProfile% in the adress bar.

Paste the file here.

4. Restart wsl by opening a terminal in VSC for example. Run:
```sh
wsl --shutdown
```

5. Then run:
```sh
wsl
```
to open wsl and run the following command to verify the cgroup version:
```sh
stat -fc %T /sys/fs/cgroup/
```
it should output: cgroup2fs

Then restart Docker Engine (restart Docker Engine) and run (add sudo before the command if it says permission denied):
```sh
docker info | grep -i cgroup
```
to verify docker cgroup version. It should output something like:
```
Cgroup Driver: cgroupfs
 Cgroup Version: 2
  cgroupns
```