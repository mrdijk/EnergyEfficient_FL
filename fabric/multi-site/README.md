# Multi-site FABRIC solution
This folder also deploys DYNAMOS in FABRIC, however, then on multiple sites (i.e. different sites/hosts for the VMs on different locations).

It uses Kubespray instead of Kubeadm and some slight changes to the main solution here for the multi-site FABRIC solution, such as multiple networks, etc. It clones Kubespray on the node and applies a custom ansible.cfg file for the kubernetes cluster setup.