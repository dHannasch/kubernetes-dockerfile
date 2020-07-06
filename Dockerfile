FROM alpine:edge

RUN apk add --no-cache kubernetes --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ --allow-untrusted
