# linuxkit k8s test

1. Install linux kit https://github.com/linuxkit/linuxkit
    * curently only tested on linux with qemu so if you're not using that it probably wont work
1. Run `make build`
1. Run `make run`
1. In another terminal run `make ssh-kubelet`
1. Run `kubeadm init --config /etc/kubernetes/kubeadm.yaml`
1. Run kubectl commands and probably break things
