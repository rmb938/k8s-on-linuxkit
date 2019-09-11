OUTPUT_DIR ?= .

build: clean
	linuxkit build -disable-content-trust -dir $(OUTPUT_DIR) kube-node.yml

clean:
	rm -rf *-state/

run:
	linuxkit run qemu -cpus 2 -mem 3072 -publish 2222:22 -disk size=4G kube-node

ssh:
	ssh -p 2222 -o LogLevel=FATAL -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o IdentitiesOnly=yes -t root@localhost ctr --namespace services.linuxkit tasks exec --tty --exec-id ssh-kubelet kubelet ash -l
