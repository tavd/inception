#!/bin/sh

set -e

CONFIG_FILE="/var/www/wp-config.php"
DB_PASSWORD_FILE="/run/secrets/db_password"

# Configure WordPress only if CONFIG_FILE doesn't exist
if [ ! -f "$CONFIG_FILE" ]; then

    # If the variable is unset or empty, stop with the error message
    : "${DB_NAME:?DB_NAME environment variable is required}"
    : "${DB_USER:?DB_USER environment variable is required}"

    # Check if this file exists and is readable (-r)
    if [ ! -r "$DB_PASSWORD_FILE" ]; then
        echo "Error: database password secret is missing or unreadable." >&2
        exit 1
    fi

    DB_PASS="$(cat "$DB_PASSWORD_FILE")"

    # Generate the WordPress database config file
    cat > "$CONFIG_FILE" << EOF
<?php
define( 'DB_NAME', '${DB_NAME}' );
define( 'DB_USER', '${DB_USER}' );
define( 'DB_PASSWORD', '${DB_PASS}' );
define( 'DB_HOST', 'mariadb' );
define( 'DB_CHARSET', 'utf8' );
define( 'DB_COLLATE', '' );
define( 'FS_METHOD', 'direct' );
\$table_prefix = 'wp_';
define( 'WP_DEBUG', false );

if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', __DIR__ . '/' );
}

require_once ABSPATH . 'wp-settings.php';
EOF

fi