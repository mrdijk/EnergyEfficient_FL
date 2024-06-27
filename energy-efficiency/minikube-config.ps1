# Use the docker driver 
minikube config set driver docker

# Use the containerd runtime (supports cgroupv2)
minikube config set container-runtime containerd

# extra-config:
#   kubelet.cgroup-driver: systemd
#   kubelet.cgroups-per-qos: "true"
#   kubelet.enforce-node-allocatable: "pods"