FROM alpine:3.10
MAINTAINER Phillip Clark <phillip@flitbit.com>

COPY rootfs /

RUN set -ex &&\
    printf "nameserver 1.1.1.1\nnameserver 8.8.8.8\nnameserver 8.8.4.4" > /etc/resolv.conf && \
    apk update && apk add --update --no-cache stunnel &&\
    chmod +x /opt/run-stunnel.sh &&\
    rm -rf /tmp/* \
           /var/cache/apk/*

ENTRYPOINT ["/opt/run-stunnel.sh"]
