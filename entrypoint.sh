#!/bin/ash
set -e

SQUID=$(which squid)

create_log_dir() {
    echo "Creating log dir: ${SQUID_LOG_DIR}"
    mkdir -p ${SQUID_LOG_DIR}
}

create_cache_dir() {
    echo "Creating cache dir: ${SQUID_CACHE_DIR}"
    mkdir -p ${SQUID_CACHE_DIR}
}

create_certificate_dir() {
    echo "Creating certificate dir: ${SQUID_CERT_DIR}"
    mkdir -p ${SQUID_CERT_DIR}
}

create_cert() {
    if [ ! -f "${SQUID_CERT_DIR}/ca_key.pem" ] || [ ! -f "${SQUID_CERT_DIR}/ca_cert.pem" ]; then
        echo "Creating certificate..."
        openssl req -new -newkey rsa:2048 -sha256 -days 3650 -nodes -x509 -extensions v3_ca \
            -keyout "${SQUID_CERT_DIR}/ca_key.pem" -out "${SQUID_CERT_DIR}/ca_cert.pem" \
            -subj "/C=JP/ST=Global/L=Global/O=Squid/OU=Squid/CN=squid.local/" -utf8 -nameopt multiline,utf8
        cat "${SQUID_CERT_DIR}/ca_cert.pem" "${SQUID_CERT_DIR}/ca_key.pem" > "${SQUID_CERT_DIR}/ca_chain.pem"
    else
        echo "Certificate found..."
    fi

    if [ ! -f "${SQUID_CERT_DIR}/ca_cert.der" ]; then
        openssl x509 -in "${SQUID_CERT_DIR}/ca_cert.pem" -outform DER -out "${SQUID_CERT_DIR}/ca_cert.der"
    fi
}

clear_certs_db() {
   if [ ! -d "${SQUID_CACHE_DIR}/ssl_db" ]; then
        echo "Clearing generated certificate db..."
        /usr/lib/squid/security_file_certgen -c -s "${SQUID_CACHE_DIR}/ssl_db" -M 4MB
   fi
}

copy_default_mime_table() {
    if [ ! -f "${SQUID_CONFIG_DIR}/mime.conf" ]; then
        echo "Copying mitm table: /etc/squid/mime.conf"
        cp /etc/squid_default/mime.conf /etc/squid/mime.conf
    fi
}

create_log_dir
create_cache_dir
create_certificate_dir
create_cert
clear_certs_db
copy_default_mime_table

chown squid:squid /dev/stdout
chown squid:squid /dev/stderr


if [[ -z ${1} ]]; then
    if [[ ! -d ${SQUID_CACHE_DIR}/00 ]]; then
        echo "Initializing cache..."
        ${SQUID} -N -f /etc/squid/squid.conf -z
    fi
    echo "Starting squid..."
    exec ${SQUID} -f /etc/squid/squid.conf -NYCd 1
else
    # flag の場合
    if [ "${1#-}" != "$1" ]; then
        set -- ${SQUID} "$@"
    fi

    # サブコマンドの場合
    if ${SQUID} "$1" --help >/dev/null 2>&1
    then
        set -- ${SQUID} "$@"
    else
        echo "= '$1' is not a sqyid command: assuming shell execution." 1>&2
    fi

    exec "$@"
fi
