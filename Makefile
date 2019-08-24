build-containerd:
	linuxkit pkg build -org rmb938 -hash dev -disable-content-trust pkgs/containerd/

build-kubelet:
	linuxkit pkg build -org rmb938 -hash dev -disable-content-trust pkgs/kubelet/

build: clean build-containerd build-kubelet
	linuxkit build -disable-content-trust kube-node.yml

clean:
	rm -rf *-state/

run:
	linuxkit run qemu -cpus 2 -mem 3072 -publish 2222:22 -disk size=4G kube-node

ssh:
	ssh -p 2222 -o LogLevel=FATAL -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -t root@localhost ctr --namespace services.linuxkit tasks exec --tty --exec-id ssh-kubelet kubelet ash -l
