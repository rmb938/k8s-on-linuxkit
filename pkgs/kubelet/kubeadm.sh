#!/bin/sh

if [ -e /var/lib/kubelet/config.yaml ] ; then
  echo "Kubernetes Node already has kubelet configuration"
  exit 0
fi

await=/run/kubeadm-run

echo "Waiting for ${await} to exist before running kubeadm commands"

until [ -e "${await}" ] ; do
    sleep 1
done

flag=$(awk -F '=' '$1=="kubeadm"{print $2}' RS=" " /proc/cmdline)

echo "Found kubeadm flag ${flag}"

if [ "${flag}" == "init" ]; then
  kubeadm init --config /run/kubeadm.yaml 2>&1
elif [ "${flag}" == "join" ]; then
  kubeadm join --config /run/kubeadm.yaml 2>&1
else
  echo "Unknown kubeadm flag ${flag}"
  exit 1
fi
