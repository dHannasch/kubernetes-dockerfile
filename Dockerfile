FROM alpine:edge

# https://gitlab.alpinelinux.org/alpine/aports/-/blob/master/testing/kubernetes/APKBUILD#L75
RUN ls /usr/bin
RUN apk add --no-cache kubernetes --repository http://dl-3.alpinelinux.org/alpine/edge/testing/
RUN ls /usr/bin
RUN find / -name kubeadm
RUN kubeadm --help
