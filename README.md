# k8s-on-linuxkit

This project was inspired by https://github.com/linuxkit/kubernetes. This repo aims to
provide a fully funtional and production ready LinuxKit Kubernetes Image able to be 
deployed and managed at scale.

Before using this image it is highly recommened learning how to build, maintain, and
administer Kubernetes clusters. Without this knowledge using this image will lead to
failure.

## Local Developement

1. Install linux kit https://github.com/linuxkit/linuxkit
    * curently only tested on linux with qemu so if you're not using that it probably wont work
1. Copy your public ssh key into `.ssh/id_rsa.pub`
    * If you don't do this you won't be able to ssh into the VM.
    * If you get locked out you have to kill qemu manually
      * Run `ps aux | grep -i qemu` then `kill -9` then pid
1. Login Docker to Github Package Registry
    * https://help.github.com/en/articles/configuring-docker-for-use-with-github-package-registry#authenticating-to-github-package-registry
1. Run `make build`
1. Run `make run`
1. In another terminal run `make ssh`
1. Create a kubeadm configuration at `/run/kubeadm.yaml`
    * If you feel lazy just run this `echo -e "apiVersion: kubeadm.k8s.io/v1beta2\nkind: ClusterConfiguration\nclusterName: linuxkit" > /run/kubeadm.yaml`
1. Run `echo 'init' > /run/kubeadm-run`
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

1. Copy your public ssh key into `.ssh/id_rsa.pub`
    * If you don't do this you won't be able to ssh into the machine.
    * You should not do this in a production environment!
1. Login Docker to Github Package Registry
    * https://help.github.com/en/articles/configuring-docker-for-use-with-github-package-registry#authenticating-to-github-package-registry
1. Run `make build`
1. Run `linuxkit serve`
1. Modify `ipxe` to use your workstation's IP address.
1. Start your host, boot into an iPXE shell and run the following
    ```
    dhcp
    chain http://${workstation_IP}:8080/ipxe
    ```
1. Once booted ssh into the host
    * `ssh root@${server_IP}`
1. Exec into the kubelet container
    * `ctr --namespace services.linuxkit tasks exec --tty --exec-id ssh-kubelet kubelet ash -l`
1. Create a kubeadm configuration at `/run/kubeadm.yaml`
1. Run `echo 'init' > /run/kubeadm-run`
1. Run `tail -f /hostroot/var/log/kubeadm.out.log`
1. Run kubectl commands and probably break things

### Adding additional nodes

1. Start your host, boot into an iPXE shell and run the following
    ```
    dhcp
    chain http://${workstation_IP}:8080/ipxe
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
1. Run `echo 'join' > /run/kubeadm-run`
1. Run `tail -f /hostroot/var/log/kubeadm.out.log`
1. Run kubectl commands and probably break things

## Cloud

Simply deploying via a cloud is a bit more complex as it requires some customization.

However creating a production ready cluster can take a lot of work. More specifically
needing to maintain etcd data files, dealing with scale up and down of worker nodes, ect..

As with any custom deployed Kubernetes cluster (i.e not GKE, EKS, ect...) a great deal
has to be taken to ensure cluster configuration, stability and architecture.

While no guidance will be given on how to achieve this, it should be fairly straight
forward for engineers familure with the technologies.

## Required Files

The following files only need to be created once to bootstrap the node. Once the node is part of a cluster
you never need to place these files again.

* `/run/kubeadm.yaml`
    * This is a [kubeadm configuration file](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/control-plane-flags/)
* `/run/kubeadm-run`
    * kubeadm will wait to run until this file exists.
    * The contents of that file must be `init` or `join`, this tells kubeadm that it should initialize a cluster or join an existing cluster.

These files can be created via execing into the kubelet container or other means by mounting `/run/node` from the root namespace inside another container.

Once kubeadm runs and creates the file `/var/lib/kubelet/config.yaml` it will never run again on the node.

## CGROUPS

All system services are under the `systemreserved` cgroup and all container/pod runtime services are under the `podruntime` cgroup. 

Since the OS runs in memory it is very important to make sure not to run out of memory.

It may be necessary to reserve computer resources https://kubernetes.io/docs/tasks/administer-cluster/reserve-compute-resources/ 

## Automation

When running on bare metal it is recommended to use iPXE or some sort of network booting system. If that is not possible then building a raw image and dd'ing it to a bootable device may work however there is a known [issue](https://github.com/linuxkit/linuxkit/issues/3154) that could prevent it from working.

Ansible to automate node configuration can be found here https://github.com/rmb938/ansible_k8s-on-linuxkit
