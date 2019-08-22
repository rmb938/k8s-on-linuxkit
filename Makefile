build-containerd:
	linuxkit pkg build -dev -disable-content-trust pkgs/containerd/

build-kubelet:
	linuxkit pkg build -dev -disable-content-trust pkgs/kubelet/

build: clean build-containerd build-kubelet
	linuxkit build -disable-content-trust kube-master.yml

clean:
	rm -rf kube-master-state/

run:
	linuxkit run qemu -cpus 2 -mem 3072 -publish 2222:22 -disk size=4G kube-master

ssh:
	ssh -p 2222 -o LogLevel=FATAL -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes root@localhost
