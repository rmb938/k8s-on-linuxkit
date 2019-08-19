# k8s-on-linuxkit

## Local Developement

1. Install linux kit https://github.com/linuxkit/linuxkit
    * curently only tested on linux with qemu so if you're not using that it probably wont work
1. Run `make build`
1. Run `make run`
1. In another terminal run `make ssh-kubelet`
1. Run `kubeadm init`
1. Run kubectl commands and probably break things


## Bare Metal

### Requirements

* Hosts must be able to boot via iPXE
* Hosts must have at least 3GB ram and 2 CPUs
    * If you don't have enough ram you may get a kernel panic
    * If you don't have enough cpus kubeadm will complain
* Hosts must have 1 unformatted disk device
    * If you don't have at least 1 unformatted disk everything will be lost on reboot

### Usage

1. Run `make build`
1. Run `linuxkit serve`
1. Start your host, boot into an iPXE shell and run the following
    ```
    dhcp
    chain http://${workstation_IP}:8080/ipxe
    ```
1. Once booted ssh into the host
    * `ssh -t root@${server_IP} ctr --namespace services.linuxkit tasks exec --tty --exec-id ssh-kubelet kubelet ash -l`
1. Run `kubeadm init`
1. Run kubectl commands and probably break things

## Automation

When running on bare metal it is recommended to use iPXE or some sort of network booting system. If that is not possible then building a raw image and dd'ing it to a bootable device may work however there is a known [issue](https://github.com/linuxkit/linuxkit/issues/3154) that could prevent it from working.

TODO: link to ansible to automate control plane, node joins, upgrades, ect...
