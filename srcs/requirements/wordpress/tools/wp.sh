#!/bin/sh

set -e

/usr/local/bin/wp-config-create.sh

exec php-fpm85 -F
