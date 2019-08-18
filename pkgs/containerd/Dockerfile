FROM linuxkit/alpine:86cd4f51b49fb9a078b50201d892a3c7973d48ec AS build

## Variables
ENV CONTAINERD_URL https://github.com/containerd/containerd.git
ENV CONTAINERD_VERSION v1.2.7

ENV RUNC_URL https://github.com/opencontainers/runc.git
ENV RUNC_VERSION v1.0.0-rc8

RUN apk add \
  bash \
  gcc \
  git \
  go \
  libc-dev \
  libseccomp-dev \
  linux-headers \
  make \
  musl-dev \
  btrfs-progs-dev

## RunC

RUN mkdir -p $GOPATH/src/github.com/opencontainers && \
  cd $GOPATH/src/github.com/opencontainers && \
  git clone $RUNC_URL
WORKDIR $GOPATH/src/github.com/opencontainers/runc
RUN git checkout -q $RUNC_VERSION
RUN make

## Containerd

WORKDIR $GOPATH/src/github.com/containerd/containerd
RUN git fetch
RUN git checkout -q $CONTAINERD_VERSION

RUN make binaries GO_BUILDTAGS="seccomp"

## Build final image

RUN mkdir -p /out/etc/apk && cp -r /etc/apk/* /out/etc/apk/

# util-linux because a full ns-enter is required.
# example commands: /usr/bin/nsenter --net= -F -- <ip commandline>
#                   /usr/bin/nsenter --net=/var/run/netns/cni-5e8acebe-810d-c1b9-ced0-47be2f312fa8 -F -- <ip commandline>
# NB the first ("--net=") is actually not valid -- see https://github.com/containerd/cri/issues/245
RUN apk add --no-cache --initdb -p /out \
  alpine-baselayout \
  busybox \
  ca-certificates \
  iptables \
  util-linux \
  socat \
  btrfs-progs \
  libseccomp

WORKDIR $GOPATH/src/github.com/containerd/containerd
RUN make DESTDIR=/out/usr/local install
WORKDIR $GOPATH/src/github.com/opencontainers/runc
RUN make DESTDIR=/out install

RUN ls -la /out/usr/local/bin

# generate containerd config
RUN mkdir -p /out/etc/containerd/ && \
  /out/usr/local/bin/containerd config default > /out/etc/containerd/config.toml

# Remove apk residuals. We have a read-only rootfs, so apk is of no use.
RUN rm -rf /out/etc/apk /out/lib/apk /out/var/cache

FROM scratch
WORKDIR /
COPY --from=build /out/ /

ENTRYPOINT ["/usr/local/bin/containerd"]
CMD []
