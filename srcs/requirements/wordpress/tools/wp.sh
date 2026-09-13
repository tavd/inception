#!/bin/sh

set -e

/usr/local/bin/wp-config-create.sh

until php85 -r '$m=new mysqli("mariadb", getenv("DB_USER"), trim(file_get_contents("/run/secrets/db_password")), getenv("DB_NAME")); if ($m->connect_error) exit(1);'; do

    echo "Waiting for MariaDB..."

    sleep 2

done

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