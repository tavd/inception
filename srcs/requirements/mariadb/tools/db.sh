#!/bin/sh

set -e

/usr/local/bin/setup_db.sh

exec "$@"
