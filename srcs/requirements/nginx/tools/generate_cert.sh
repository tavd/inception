#!/bin/sh
set -e

# "$0" - path to this script
# dirname "$0" - script path without the filename (directory containing the script)
CERT_DIR="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
# paths to the certificate and key files
CERT_FILE="${CERT_DIR}/tavdiiev.42.fr.crt"
KEY_FILE="${CERT_DIR}/tavdiiev.42.fr.key"

if [ ! -f "$CERT_FILE" ] || [ ! -f "$KEY_FILE" ]; then
    echo "Generating SSL certificate..."
    mkcert \
        # put the generated certificate and key in these files
        -cert-file "$CERT_FILE" \
        -key-file "$KEY_FILE" \
        # the names/addresses that the certificate is valid for
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
