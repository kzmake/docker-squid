FROM alpine:3.11

LABEL maintainer="kzmake <kzmake.i3a@gmail.com>"

ENV SQUID_VERSION=4.10 \
    SQUID_CONFIG_DIR=/etc/squid \
    SQUID_CACHE_DIR=/var/cache/squid \
    SQUID_LOG_DIR=/var/log/squid \
    SQUID_CERT_DIR=/etc/squid/cert

RUN set -xe \
    && apk add --no-cache --no-progress alpine-conf tzdata openssl ca-certificates \
    && apk add --no-cache --no-progress --purge -uU --repository http://dl-cdn.alpinelinux.org/alpine/edge/main squid \
    && update-ca-certificates \
    && mkdir -p /etc/squid_default \
    && cp -r /etc/squid/* /etc/squid_default/ \
    && ln -sf /dev/stdout /var/log/squid/access.log \
    && rm -rf /var/cache/apk/* /tmp/*

COPY entrypoint.sh /
COPY _openssl.cnf /etc/ssl

RUN chmod +x /entrypoint.sh
RUN cat /etc/ssl/_openssl.cnf >> /etc/ssl/openssl.cnf

VOLUME /etc/squid/

EXPOSE 3128 3129

ENTRYPOINT ["/entrypoint.sh"]
