build-containerd:
	linuxkit pkg build -dev -disable-content-trust pkgs/containerd/

build-kubelet:
	linuxkit pkg build -dev -disable-content-trust pkgs/kubelet/

build: build-containerd build-kubelet
	linuxkit build -disable-content-trust kube-node.yml

clean:
	rm -rf kube-node-state/ 

run:
	linuxkit run qemu -cpus 2 -mem 2048 -publish 2222:22 -disk size=4G kube-node

ssh-kubelet:
	ssh -p 2222 -o LogLevel=FATAL -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -t root@localhost ctr --namespace services.linuxkit tasks exec --tty --exec-id ssh-kubelet kubelet ash -l

ssh-containerd:
	ssh -p 2222 -o LogLevel=FATAL -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -t root@localhost ctr --namespace services.linuxkit tasks exec --tty --exec-id ssh-containerd containerd ash -l
