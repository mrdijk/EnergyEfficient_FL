# WSL2 configure cgroupv2

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