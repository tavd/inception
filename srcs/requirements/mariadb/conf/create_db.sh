#!/bin/sh

set -e

# Read the database passwords from Docker secrets
DB_PASS="$(cat /run/secrets/db_password)"
DB_ROOT="$(cat /run/secrets/db_root_password)"

# Initialize MariaDB data directory (/var/lib/mysql)
if [ ! -d "/var/lib/mysql/mysql" ]; then
    mysql_install_db \
        --basedir=/usr \
        --datadir=/var/lib/mysql \
        --user=mysql
fi

# Create and configure the database and users on the first startup
if [ ! -d "/var/lib/mysql/${DB_NAME}" ]; then

    mysqld --user=mysql --bootstrap << EOF
USE mysql;

FLUSH PRIVILEGES;

DELETE FROM mysql.user WHERE User='';

DROP DATABASE IF EXISTS test;

DELETE FROM mysql.db WHERE Db='test';

DELETE FROM mysql.user
WHERE User='root'
  AND Host NOT IN ('localhost', '127.0.0.1', '::1');

ALTER USER 'root'@'localhost'
IDENTIFIED BY '${DB_ROOT}';

CREATE DATABASE ${DB_NAME}
CHARACTER SET utf8
COLLATE utf8_general_ci;

CREATE USER '${DB_USER}'@'%'
IDENTIFIED BY '${DB_PASS}';

GRANT ALL PRIVILEGES
ON ${DB_NAME}.*
TO '${DB_USER}'@'%';

FLUSH PRIVILEGES;
EOF

fi
