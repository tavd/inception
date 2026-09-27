#!/bin/sh
set -e

CERT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
CERT_FILE="${CERT_DIR}/tavdiiev.42.fr.crt"
KEY_FILE="${CERT_DIR}/tavdiiev.42.fr.key"

if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    echo "Generating SSL certificate..."
    mkcert \
        -cert-file "$CERT_FILE" \
        -key-file "$KEY_FILE" \
        tavdiiev.42.fr \
        www.tavdiiev.42.fr \
        localhost \
        127.0.0.1 \
        ::1

    chmod 644 "$CERT_FILE"
    chmod 600 "$KEY_FILE"

    echo "SSL certificate generated."
else
    echo "SSL certificate already exists."
fi
