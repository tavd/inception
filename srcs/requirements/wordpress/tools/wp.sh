#!/bin/sh

set -e

/usr/local/bin/create_config.sh

# Ensure WordPress uses the configured MariaDB port
if [ -f /var/www/wp-config.php ]; then
    sed -i "s/define( 'DB_HOST', '[^']*' );/define( 'DB_HOST', 'mariadb:3306' );/" \
        /var/www/wp-config.php
fi

# Wait until MariaDB is ready to accept connections
until php85 -r '
    $m = new mysqli(
        "mariadb",
        getenv("DB_USER"),
        trim(file_get_contents("/run/secrets/db_password")),
        getenv("DB_NAME"),
        3306
    );
    if ($m->connect_error) {
        exit(1);
    }
'; do
    echo "Waiting for MariaDB..."
    sleep 2
done

# Install WordPress and create the additional user if WordPress is not installed yet
if ! wp core is-installed --allow-root; then
    echo "WordPress is not installed. Installing..."
    wp core install \
        --url="$WP_URL" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$(cat /run/secrets/wp_admin_password)" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root
    wp user create \
        "$WP_USER" \
        "$WP_USER_EMAIL" \
        --role=subscriber \
        --user_pass="$(cat /run/secrets/wp_user_password)" \
        --allow-root
else
    echo "WordPress is already installed."
fi

exec php-fpm85 -F