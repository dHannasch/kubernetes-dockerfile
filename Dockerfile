FROM alpine:edge

# The kube* binaries do get put in /usr/bin: https://gitlab.alpinelinux.org/alpine/aports/-/blob/master/testing/kubernetes/APKBUILD#L75
RUN apk add --no-cache kubernetes --repository http://dl-3.alpinelinux.org/alpine/edge/testing/
RUN apk add --no-cache kubelet --repository http://dl-3.alpinelinux.org/alpine/edge/testing/
RUN apk add --no-cache kubeadm --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/
RUN apk --upgrade add --no-cache docker --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/
RUN apk --upgrade add --no-cache openrc --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/

#RUN apk --upgrade add --no-cache modprobe --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/
#RUN apk --upgrade add --no-cache modprobe
#RUN docker info # Even with openrc installed, this fails saying ERROR: Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
#RUN rc-update add kubeadm # rc-update: service `kubeadm' does not exist
# kubeadm init yields [WARNING Service-Docker]: docker service is not enabled, please run 'rc-update add docker default'
RUN rc-update add docker default
RUN rc-update add kubelet default
#RUN rc-service kubeadm start
#RUN rc-service docker start # fails saying docker is already starting
#RUN service docker start # also fails saying docker is already starting

# [ERROR FileContent--proc-sys-net-bridge-bridge-nf-call-iptables]: /proc/sys/net/bridge/bridge-nf-call-iptables does not exist
# Load required modules
# https://github.com/moby/moby/issues/1799
RUN echo overlay > /etc/modules-load.d/containerd.conf
RUN echo br_netfilter >> /etc/modules-load.d/containerd.conf
RUN cat /etc/modules-load.d/containerd.conf
# impossible to modprobe? https://gitlab.alpinelinux.org/alpine/aports/-/issues/10861
#RUN modprobe overlay
#RUN modprobe br_netfilter

# Setup required sysctl params, these persist across reboots.
RUN echo "net.bridge.bridge-nf-call-iptables  = 1" >  /etc/sysctl.d/99-kubernetes-cri.conf
RUN echo "net.ipv4.ip_forward                 = 1" >> /etc/sysctl.d/99-kubernetes-cri.conf
RUN echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.d/99-kubernetes-cri.conf
RUN sysctl -p
RUN sysctl -p /etc/sysctl.d/99-kubernetes-cri.conf

# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#letting-iptables-see-bridged-traffic
RUN lsmod | grep br_netfilter
RUN echo "net.bridge.bridge-nf-call-ip6tables = 1" >  /etc/sysctl.d/k8s.conf
RUN echo "net.bridge.bridge-nf-call-iptables  = 1" >> /etc/sysctl.d/k8s.conf
# RUN sysctl --system crashes with sysctl: unrecognized option: system
RUN sysctl -p /etc/sysctl.d/k8s.conf

# [ERROR Swap]: running with swap on is not supported. Please disable swap
# disable swap:
RUN sed --in-place '/swap/d' /etc/fstab
RUN swapoff -a

#RUN kubeadm init
