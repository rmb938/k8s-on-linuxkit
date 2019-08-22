# k8s-on-linuxkit

## Local Developement

1. Install linux kit https://github.com/linuxkit/linuxkit
    * curently only tested on linux with qemu so if you're not using that it probably wont work
1. Run `make build`
1. Run `make run`
1. In another terminal run `make ssh`
1. Create a kubeadm configuration at `/run/kubeadm.yaml`
    * If you feel lazy just run this `echo -e "apiVersion: kubeadm.k8s.io/v1beta2\nkind: ClusterConfiguration\nclusterName: linuxkit" > /run/kubeadm.yaml`
1. Run `touch /run/kubeadm-run`
1. Run `tail -f /hostroot/var/log/kubeadm.out.log`
    * Once kubeadm says it's initialized successfully you can exit
1. Run kubectl commands and probably break things
1. When you are done run `poweroff -f`

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
    chain http://${workstation_IP}:8080/ipxe-master
    ```
1. Once booted ssh into the host
    * `ssh root@${server_IP}`
1. Exec into the kubelet container
    * `ctr --namespace services.linuxkit tasks exec --tty --exec-id ssh-kubelet kubelet ash -l`
1. Create a kubeadm configuration at `/run/kubeadm.yaml`
1. Run `touch /run/kubeadm-run`
1. Run `tail -f /hostroot/var/log/kubeadm.out.log`
1. Run kubectl commands and probably break things

### Adding additional nodes

1. Start your host, boot into an iPXE shell and run the following
    ```
    dhcp
    chain http://${workstation_IP}:8080/ipxe-node
    ```
1. Once booted ssh into the host
    * `ssh root@${server_IP}`
1. Exec into the kubelet container
    * `ctr --namespace services.linuxkit tasks exec --tty --exec-id ssh-kubelet kubelet ash -l`
1. Create a kubeadm configuration at `/run/kubeadm.yaml`
    * Use the master to get a kubeadm token and connection information, an example `kubeadm.yaml` is bellow
        ```
        apiVersion: kubeadm.k8s.io/v1beta2
        kind: JoinConfiguration
        discovery:
          bootstrapToken:
            token: $TOKEN
            apiServerEndpoint: $MASTER_IP:6443
            caCertHashes:
              - $DISCOVERY_TOKEN_CA_CERT_HASH
            unsafeSkipCAVerification: false
        ```
1. Run `touch /run/kubeadm-run`
1. Run `tail -f /hostroot/var/log/kubeadm.out.log`
1. Run kubectl commands and probably break things

## Kernel Flags

### `kubeadm`

A custom kernel flag with the key of `kubeadm` has been added, by default the value is `init`.

#### Required Files

The files listed bellow are required for kubeadm to run.

* `/run/kubeadm.yaml`
    * This is a [kubeadm configuration file](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/control-plane-flags/)
* `/run/kubeadm-run`
    * kubeadm will wait to run until this file exists.

These files can be created via execing into the kubelet container or other means by mounting `/run/node:/run` inside another container.

Once kubeadm runs and creates the file `/var/lib/kubelet/config.yaml` it will never run again on the node.

#### Values

##### `init`

**Only one node in the kubernetes cluster can have this flag**

This flag tells the node to initialize a new kubernetes cluster.

##### `join`

This flag tells the node to join an existing kubernetes cluster.

## Automation

When running on bare metal it is recommended to use iPXE or some sort of network booting system. If that is not possible then building a raw image and dd'ing it to a bootable device may work however there is a known [issue](https://github.com/linuxkit/linuxkit/issues/3154) that could prevent it from working.

TODO: link to ansible for automation
