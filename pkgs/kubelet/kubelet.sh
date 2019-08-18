#!/bin/sh

if [ ! -e /opt/cni/bin/.opt.defaults-extracted ] ; then
    tar -xzvf /root/cni.tgz -C /opt/cni/bin
    touch /opt/cni/bin/.opt.defaults-extracted
fi

mkdir -p /etc/kubernetes/manifests

cat > /etc/kubernetes/kubeadm.yaml << EOF
apiVersion: kubeadm.k8s.io/v1beta1
kind: InitConfiguration
nodeRegistration:
  criSocket: /run/containerd/containerd.sock
  kubeletExtraArgs:
    container-runtime: remote
    runtime-request-timeout: 15m
    container-runtime-endpoint: unix:///run/containerd/containerd.sock
EOF

await=/etc/kubernetes/manifests/kube-scheduler.yaml

echo "kubelet.sh: waiting for ${await}"

until [ -f "${await}" ] ; do
    sleep 1
done

echo "kubelet.sh: ${await} has arrived"

. /var/lib/kubelet/kubeadm-flags.env

kubelet --network-plugin=cni --cni-conf-dir=/etc/cni/net.d --cni-bin-dir=/opt/cni/bin --config=/var/lib/kubelet/config.yaml --kubeconfig=/etc/kubernetes/kubelet.conf --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf $KUBELET_ARGS $KUBELET_KUBEADM_ARGS $@
