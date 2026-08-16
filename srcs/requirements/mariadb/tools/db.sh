#!/bin/sh

set -e

/usr/local/bin/create_db.sh

exec "$@"
