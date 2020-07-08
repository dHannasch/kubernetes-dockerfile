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
#RUN rc-service docker start   # crashes saying "docker is already starting"
#RUN rc-service docker restart # crashes saying "docker is already starting"
#RUN service docker start      # crashes saying "docker is already starting"

# [ERROR FileContent--proc-sys-net-bridge-bridge-nf-call-iptables]: /proc/sys/net/bridge/bridge-nf-call-iptables does not exist
# Load required modules
# https://github.com/moby/moby/issues/1799
RUN echo overlay > /etc/modules-load.d/containerd.conf
RUN echo br_netfilter >> /etc/modules-load.d/containerd.conf
RUN cat /etc/modules-load.d/containerd.conf
# impossible to modprobe? https://gitlab.alpinelinux.org/alpine/aports/-/issues/10861
#RUN modprobe overlay
#RUN modprobe br_netfilter

# https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/#letting-iptables-see-bridged-traffic
RUN lsmod | grep br_netfilter
# yields:
# br_netfilter 24576 0
# bridge 126976 1 br_netfilter
RUN lsmod | grep overlay
RUN echo "net.bridge.bridge-nf-call-ip6tables = 1" >  /etc/sysctl.d/k8s.conf
RUN echo "net.bridge.bridge-nf-call-iptables  = 1" >> /etc/sysctl.d/k8s.conf
# RUN sysctl --system crashes with sysctl: unrecognized option: system
RUN sysctl -p /etc/sysctl.d/k8s.conf
# yields:
# sysctl: error: 'net.bridge/bridge-nf-call-ip6tables' is an unknown key
# sysctl: error: 'net.bridge/bridge-nf-call-iptables' is an unknown key
# even though lsmod | grep br_netfilter and lsmod | grep overlay appear to indicate success

# Setup required sysctl params, these persist across reboots.
RUN echo "net.bridge.bridge-nf-call-iptables  = 1" >  /etc/sysctl.d/99-kubernetes-cri.conf
RUN echo "net.ipv4.ip_forward                 = 1" >> /etc/sysctl.d/99-kubernetes-cri.conf
RUN echo "net.bridge.bridge-nf-call-ip6tables = 1" >> /etc/sysctl.d/99-kubernetes-cri.conf
RUN sysctl -p
RUN sysctl -p /etc/sysctl.d/99-kubernetes-cri.conf
# yields:
# sysctl: error: 'net.bridge/bridge-nf-call-iptables' is an unknown key
# sysctl: error setting key 'net.ipv4.ip_forward': Read-only file system
# sysctl: error: 'net.bridge/bridge-nf-call-ip6tables' is an unknown key
# even though lsmod | grep br_netfilter and lsmod | grep overlay appear to indicate success

# [ERROR Swap]: running with swap on is not supported. Please disable swap
# disable swap:
RUN sed --in-place '/swap/d' /etc/fstab
RUN swapoff -a

#RUN kubeadm init
