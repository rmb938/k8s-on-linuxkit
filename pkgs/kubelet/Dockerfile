FROM linuxkit/alpine:86cd4f51b49fb9a078b50201d892a3c7973d48ec AS build

## Variables
ENV KUBERENTES_URL https://github.com/kubernetes/kubernetes.git
ENV KUBERNETES_VERSION v1.15.2

ENV CRITOOLS_URL https://github.com/kubernetes-sigs/cri-tools.git
ENV CRITOOLS_VERSION v1.15.0

ENV CNIPLUGINS_URL https://github.com/containernetworking/plugins.git
ENV CNIPLUGINS_VERSION v0.8.2

RUN echo "@edge-main http://dl-cdn.alpinelinux.org/alpine/edge/main" >> /etc/apk/repositories
RUN echo "@edge-community http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories

RUN apk add --no-cache -U \
  bash \
  coreutils \
  curl \
  findutils \
  git \
  go@edge-community \
  binutils@edge-main \
  grep \
  libc-dev \
  linux-headers \
  make \
  rsync

## Kubernetes

RUN mkdir -p $GOPATH/src/github.com/kubernetes/ && \
  cd $GOPATH/src/github.com/kubernetes/ && \
  git clone $KUBERENTES_URL
WORKDIR $GOPATH/src/github.com/kubernetes/kubernetes
RUN git checkout -q $KUBERNETES_VERSION
RUN make WHAT="cmd/kubelet cmd/kubectl cmd/kubeadm"

## CNI Plugins

RUN mkdir -p $GOPATH/src/github.com/containernetworking/ && \
  cd $GOPATH/src/github.com/containernetworking/ && \
  git clone $CNIPLUGINS_URL
WORKDIR $GOPATH/src/github.com/containernetworking/plugins
RUN git checkout -q $CNIPLUGINS_VERSION
RUN ./build_linux.sh

## CRI Tools

RUN mkdir -p $GOPATH/src/github.com/kubernetes-sigs && \
  cd $GOPATH/src/github.com/kubernetes-sigs && \
  git clone $CRITOOLS_URL
WORKDIR $GOPATH/src/github.com/kubernetes-sigs/cri-tools
RUN git checkout -q $CRITOOLS_VERSION
RUN make binaries

## Build final image

RUN mkdir -p /out/etc/apk && cp -r /etc/apk/* /out/etc/apk/

#coreutils needed for du -B for disk image checks made by kubelet
# example: $ du -s -B 1 /var/lib/kubelet/pods/...
#          du: unrecognized option: B
RUN apk add --no-cache --initdb -p /out \
  alpine-baselayout \
  busybox \
  ca-certificates \
  coreutils \
  curl \
  ebtables \
  ethtool \
  findutils \
  iproute2 \
  iptables \
  musl \
  openssl \
  socat \
  util-linux \
  nfs-utils

RUN cp $GOPATH/src/github.com/kubernetes/kubernetes/_output/bin/kubelet /out/usr/local/bin/kubelet
RUN cp $GOPATH/src/github.com/kubernetes/kubernetes/_output/bin/kubeadm /out/usr/local/bin/kubeadm
RUN cp $GOPATH/src/github.com/kubernetes/kubernetes/_output/bin/kubectl /out/usr/local/bin/kubectl

RUN tar -czvf /out/root/cni.tgz -C $GOPATH/src/github.com/containernetworking/plugins/bin .

RUN cp $GOPATH/bin/crictl /out/usr/local/bin/crictl
RUN cp $GOPATH/bin/critest /out/usr/local/bin/critest

COPY kubelet.sh /out/usr/local/bin/kubelet.sh

RUN ls -la /out/usr/local/bin/

# Remove apk residuals. We have a read-only rootfs, so apk is of no use.
RUN rm -rf /out/etc/apk /out/lib/apk /out/var/cache

FROM scratch
WORKDIR /
COPY --from=build /out /

ENV KUBECONFIG "/etc/kubernetes/admin.conf"

ENTRYPOINT ["/usr/local/bin/kubelet.sh"]
CMD []
