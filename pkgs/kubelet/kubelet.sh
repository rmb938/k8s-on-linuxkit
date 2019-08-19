#!/bin/sh

if [ ! -e /opt/cni/bin/.opt.defaults-extracted ] ; then
    tar -xzvf /root/cni.tgz -C /opt/cni/bin
    touch /opt/cni/bin/.opt.defaults-extracted
fi

mkdir -p /etc/kubernetes/manifests

await=/var/lib/kubelet/config.yaml

echo "kubelet.sh: waiting for ${await}"

until [ -f "${await}" ] ; do
    sleep 1
done

echo "kubelet.sh: ${await} has arrived"
echo "sleeping a bit more to make sure the other files are written"

sleep 5

. /var/lib/kubelet/kubeadm-flags.env

KUBELET_CNI_ARGS="--network-plugin=cni --cni-conf-dir=/etc/cni/net.d --cni-bin-dir=/opt/cni/bin"

kubelet --config=/var/lib/kubelet/config.yaml --kubeconfig=/etc/kubernetes/kubelet.conf --bootstrap-kubeconfig=/etc/kubernetes/bootstrap-kubelet.conf $KUBELET_CNI_ARGS $KUBELET_ARGS $KUBELET_KUBEADM_ARGS $@
