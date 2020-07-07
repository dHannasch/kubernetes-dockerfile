FROM alpine:edge

# binaries get put in /usr/bin https://gitlab.alpinelinux.org/alpine/aports/-/blob/master/testing/kubernetes/APKBUILD#L75
RUN apk add --no-cache kubernetes --repository http://dl-3.alpinelinux.org/alpine/edge/testing/
RUN apk add --no-cache kubelet --repository http://dl-3.alpinelinux.org/alpine/edge/testing/
RUN apk add --no-cache kubeadm --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/
RUN apk --upgrade add --no-cache docker --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/
RUN apk --upgrade add --no-cache openrc --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing/
#RUN docker info # Even with openrc installed, this fails saying ERROR: Cannot connect to the Docker daemon at unix:///var/run/docker.sock. Is the docker daemon running?
#RUN rc-update add kubeadm # rc-update: service `kubeadm' does not exist
# kubeadm init yields [WARNING Service-Docker]: docker service is not enabled, please run 'rc-update add docker default'
RUN rc-update add docker default
#RUN rc-service kubeadm start
#RUN rc-service docker start # fails saying docker is already starting
#RUN service docker start # also fails saying docker is already starting
RUN echo overlay > /etc/modules-load.d/containerd.conf
RUN echo br_netfilter >> /etc/modules-load.d/containerd.conf
RUN cat /etc/modules-load.d/containerd.conf
RUN modprobe overlay
RUN modprobe br_netfilter

#RUN kubeadm init
