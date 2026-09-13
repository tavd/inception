# Inception — Developer Documentation

## Overview

This document explains the internal structure, configuration, build process, networking, persistence, security, and development workflow of the Inception project.

The project consists of three Docker services:

- **NGINX** — public HTTPS entry point.
- **WordPress/PHP-FPM** — application and PHP execution layer.
- **MariaDB** — database layer.

The services communicate through a private Docker bridge network named `inception`.

The architecture is:

Browser
   │
   │ HTTPS :443
   ▼
NGINX
   │
   │ FastCGI :9000
   ▼
WordPress / PHP-FPM
   │
   │ MySQL :3306
   ▼
MariaDB

Only NGINX publishes a port. WordPress/PHP-FPM and MariaDB are internal services.

## Project Structure

```text
inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── nginx.conf
        │   └── tools/
        │       ├── tavdiiev.42.fr.crt
        │       └── tavdiiev.42.fr.key
        │
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── wp-config-create.sh
        │   └── tools/
        │       └── wp.sh
        │
        └── mariadb/
            ├── Dockerfile
            ├── conf/
            │   └── create_db.sh
            └── tools/
                └── db.sh
```

The `.env`, secret files, certificate, and private key are local environment-specific files and are excluded from Git.

## Prerequisites

The development environment requires:

* Docker
* Docker Compose
* Git
* Bash
* A Linux environment capable of running Docker

The current project uses Alpine Linux 3.23 as the base image for all three services.

## Setting Up Environment From Scratch

### Clone the repository

```bash
git clone <repository-url>
cd inception
```

### Create the local `.env`

The Makefile expects:

```text
srcs/.env
```

A typical configuration is:

```env
DOMAIN_NAME=tavdiiev.42.fr
CERT_=./requirements/tools/tavdiiev.42.fr.crt
KEY_=./requirements/tools/tavdiiev.42.fr.key
DB_NAME=wordpress
DB_USER=wpuser
WP_TITLE=Inception
WP_ADMIN_USER=tavd_user1
WP_ADMIN_EMAIL=some_email@gmail.com
WP_USER=tavd_user2
WP_USER_EMAIL=some_email2@gmail.com
WP_URL=https://tavdiiev.42.fr
```

`WP_URL` must remain the canonical project URL without `:8443`.

Port `8443` is only used by the school VirtualBox environment as a host-side forwarding port.

### Create the secrets

The project expects four secret files:

```text
secrets/
├── db_password.txt
├── db_root_password.txt
├── wp_admin_password.txt
└── wp_user_password.txt
```

Their purposes are:

* `db_password.txt` — password for the MariaDB database user used by WordPress.
* `db_root_password.txt` — MariaDB root password.
* `wp_admin_password.txt` — WordPress administrator password.
* `wp_user_password.txt` — normal/subscriber WordPress user password.

The files contain sensitive information and must not be committed to Git.

### TLS certificate and key

NGINX expects the certificate and private key at:

```text
srcs/requirements/nginx/tools/tavdiiev.42.fr.crt
srcs/requirements/nginx/tools/tavdiiev.42.fr.key
```

These files are local environment-specific files and are excluded from Git.

## School Environment and Browser Access

The project itself uses:

```text
NGINX :443
WP_URL=https://tavdiiev.42.fr
```

In the school VM setup, VirtualBox forwards:

```text
Host 127.0.0.1:8443 → VM 443
```

Therefore `8443` is not part of the project's actual NGINX or WordPress configuration.

The VM resolves the domain locally:

```text
127.0.0.1    localhost tavdiiev.42.fr
```

When testing from the school host, the recommended clean test is:

```bash
curl -kI -H "Host: tavdiiev.42.fr" https://127.0.0.1:8443/
```

A successful response such as:

```text
HTTP/1.1 200 OK
```

confirms the path:

```text
School host
    │
    │ 127.0.0.1:8443
    ▼
VirtualBox
    │
    │ VM :443
    ▼
NGINX
    │
    ▼
WordPress
```

A browser request to:

```text
https://tavdiiev.42.fr:8443/
```

may be redirected by WordPress to the canonical URL:

```text
https://tavdiiev.42.fr/
```

because the stored `home` and `siteurl` values do not contain `:8443`.

If browser testing specifically through `8443` is required, the `home` and `siteurl` WordPress options can temporarily be changed to include `:8443`. They should then be restored to:

```text
https://tavdiiev.42.fr
```

Do not put `:8443` into the final `WP_URL`.

## Initial WordPress Installation

WordPress installation is automated.

The WordPress container starts with:

```text
/usr/local/bin/wp.sh
```

The script performs the following operations:

1. Runs `wp-config-create.sh`.
2. Waits until MariaDB accepts a connection.
3. Checks whether WordPress is already installed.
4. If WordPress is not installed, runs `wp core install`.
5. Creates the configured normal/subscriber user with `wp user create`.
6. Starts PHP-FPM in the foreground.

The relevant logic is:

```text
wp.sh
  │
  ├── wp-config-create.sh
  │
  ├── wait for MariaDB
  │
  ├── wp core is-installed
  │
  ├── if not installed:
  │      ├── wp core install
  │      └── wp user create
  │
  └── php-fpm85 -F
```

The administrator password is read from:

```text
/run/secrets/wp_admin_password
```

The normal user password is read from:

```text
/run/secrets/wp_user_password
```

The database password is read from:

```text
/run/secrets/db_password
```

### First installation

On empty WordPress data, the logs should contain messages similar to:

```text
WordPress is not installed. Installing...
Success: WordPress installed successfully.
Success: Created user 2.
```

### Existing installation

If WordPress already exists in persistent storage:

```text
WordPress is already installed.
```

The installation and user creation steps are skipped.

This prevents duplicate users and repeated installation when the container is recreated.

### Verify installation

```bash
docker exec wordpress wp core is-installed --allow-root
```

Check the version:

```bash
docker exec wordpress wp core version --allow-root
```

List users:

```bash
docker exec wordpress wp user list --allow-root
```

## Building Project

From the project root:

```bash
make
```

The Makefile creates the required persistent-data directories if necessary and starts Docker Compose.

To rebuild the images:

```bash
make build
```

The Compose command uses:

```text
srcs/docker-compose.yml
```

and:

```text
srcs/.env
```

## Launching Project

The normal startup command is:

```bash
make
```

or:

```bash
make all
```

The services are started in detached mode.

Check them with:

```bash
docker ps
```

Expected containers:

```text
nginx
wordpress
mariadb
```

## Checking Docker Network

The project uses:

```yaml
networks:
  inception:
    driver: bridge
```

All services are connected to this network.

Check the network:

```bash
docker network ls
```

Inspect it:

```bash
docker network inspect inception
```

Docker's internal DNS allows:

```text
wordpress → mariadb:3306
nginx → wordpress:9000
```

No service requires a hard-coded container IP address.

## Managing Containers

Show running containers:

```bash
docker ps
```

Show all containers:

```bash
docker ps -a
```

Inspect a container:

```bash
docker inspect nginx
docker inspect wordpress
docker inspect mariadb
```

View logs:

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

Follow logs:

```bash
docker logs -f wordpress
```

## Managing Project With Makefile

Available Makefile targets:

```text
all
build
down
re
clean
fclean
```

### `make`

Starts the existing configuration.

### `make build`

Builds the images and starts the services.

### `make down`

Stops and removes the Compose containers and network.

Persistent data is normally preserved.

### `make re`

Stops the current infrastructure, rebuilds it, and starts it again.

### `make clean`

Performs project cleanup.

Use with caution because persistent data may be affected.

### `make fclean`

Performs more extensive Docker cleanup.

Use with particular caution because persistent project data may be deleted.

## Managing Docker Compose Directly

The project can also be managed directly with Docker Compose.

Start:

```bash
docker-compose -f ./srcs/docker-compose.yml --env-file srcs/.env up -d
```

Build and start:

```bash
docker-compose -f ./srcs/docker-compose.yml --env-file srcs/.env up -d --build
```

Stop and remove containers:

```bash
docker-compose -f ./srcs/docker-compose.yml --env-file srcs/.env down
```

Avoid:

```bash
docker-compose down -v
```

unless intentionally resetting persistent data.

## Managing Volumes

The project defines two named Docker volumes:

```text
wp-volume
db-volume
```

Their storage is backed by:

```text
/home/${USER}/data/wordpress
/home/${USER}/data/mariadb
```

The Compose configuration uses:

```yaml
volumes:
  wp-volume:
    driver_opts:
      o: bind
      type: none
      device: /home/${USER}/data/wordpress

  db-volume:
    driver_opts:
      o: bind
      type: none
      device: /home/${USER}/data/mariadb
```

The volumes are mounted as:

```text
wp-volume → /var/www/
db-volume → /var/lib/mysql
```

Use the project's defined named volumes and required host storage layout. Do not replace them with unrelated host bind mounts or another persistence mechanism.

## Persistent Data

Persistent WordPress files are stored under:

```text
/home/${USER}/data/wordpress
```

Persistent MariaDB data is stored under:

```text
/home/${USER}/data/mariadb
```

This data survives normal container recreation.

Deleting the MariaDB storage can destroy the WordPress database, including users and settings.

## NGINX Configuration

The NGINX server listens on HTTPS port 443:

```nginx
server {
    listen 443 ssl;
    server_name tavdiiev.42.fr www.tavdiiev.42.fr;
```

The document root is:

```nginx
root /var/www/;
```

The default index is:

```nginx
index index.php;
```

TLS is configured with:

```nginx
ssl_protocols TLSv1.2 TLSv1.3;
```

PHP requests are passed to:

```nginx
fastcgi_pass wordpress:9000;
```

The PHP script filename is constructed with:

```nginx
fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
```

The NGINX container is the only service published outside the Docker network.

## WordPress Configuration

The WordPress configuration is generated by:

```text
srcs/requirements/wordpress/conf/wp-config-create.sh
```

It creates:

```text
/var/www/wp-config.php
```

only if the file does not already exist.

The database configuration uses:

```text
DB_NAME
DB_USER
/run/secrets/db_password
DB_HOST=mariadb
```

The database host is the Docker service name:

```text
mariadb
```

not a container IP address.

The table prefix is:

```text
wp_
```

The project uses:

```text
FS_METHOD=direct
WP_DEBUG=false
```

## MariaDB Configuration

MariaDB is initialized by:

```text
srcs/requirements/mariadb/conf/create_db.sh
```

The script:

1. Initializes the MariaDB data directory when necessary.
2. Reads the database and root passwords from Docker secrets.
3. Removes the default anonymous users.
4. Removes the default test database.
5. Configures the MariaDB root password.
6. Creates the WordPress database.
7. Creates the WordPress database user.
8. Grants the required privileges.

The database is only initialized when the persistent database has not already been initialized.

MariaDB listens internally on port 3306.

It is not published to the host.

## Docker Secrets and Security

The project uses four Docker secrets:

```text
db_password.txt
db_root_password.txt
wp_admin_password.txt
wp_user_password.txt
```

The Compose configuration maps them into the containers under:

```text
/run/secrets/
```

Passwords are therefore not stored directly in Dockerfiles or Compose environment variables.

The `.env` file contains non-sensitive configuration and is excluded from Git.

The secret directory is also excluded from Git.

The TLS private key is excluded from Git.

## Rebuilding After Configuration Changes

After changing Dockerfiles or other image-build configuration:

```bash
make build
```

After changing Compose configuration:

```bash
make down
make
```

For a complete rebuild:

```bash
make re
```

Be careful when cleaning volumes because the WordPress and MariaDB data is persistent.

## Troubleshooting

### WordPress automatic installation does not complete

Check the WordPress logs:

```bash
docker logs wordpress
```

Look for:

```text
Waiting for MariaDB...
```

or:

```text
WordPress is not installed. Installing...
```

Check whether WordPress is installed:

```bash
docker exec wordpress wp core is-installed --allow-root
```

Check the WordPress version:

```bash
docker exec wordpress wp core version --allow-root
```

Check the users:

```bash
docker exec wordpress wp user list --allow-root
```

If testing from completely clean data, remember that deleting the persistent WordPress and MariaDB data resets the installation.

### MariaDB does not start

Check:

```bash
docker logs mariadb
```

Check the container:

```bash
docker inspect mariadb
```

Check that the required secrets exist and are readable by the containers.

### NGINX does not start

Check:

```bash
docker logs nginx
```

Verify the certificate and key exist.

Check the NGINX configuration:

```bash
docker exec nginx nginx -t
```

### WordPress cannot connect to MariaDB

Verify the service is running:

```bash
docker ps
```

Verify network connectivity:

```bash
docker network inspect inception
```

The WordPress container should use:

```text
mariadb
```

as the database host.

### School host HTTPS test

From the school host:

```bash
curl -kI -H "Host: tavdiiev.42.fr" https://127.0.0.1:8443/
```

A successful response should be similar to:

```text
HTTP/1.1 200 OK
Server: nginx
```

This tests the host-to-VM forwarded connection without changing the canonical WordPress URL.

### Browser redirects from port 8443

This can happen because WordPress is configured with:

```text
https://tavdiiev.42.fr
```

rather than:

```text
https://tavdiiev.42.fr:8443
```

This is expected.

Do not permanently change `WP_URL` to include `:8443`.

## Cleaning Project

Do not use destructive cleanup commands unless intentionally resetting the project.

In particular:

```bash
docker-compose down -v
```

removes Docker volumes.

The project's `make clean` and `make fclean` targets should also be treated as potentially destructive operations.

Deleting:

```text
/home/${USER}/data/mariadb
```

removes the persistent MariaDB database.

Deleting:

```text
/home/${USER}/data/wordpress
```

removes the persistent WordPress installation.

## Development Workflow

A normal development workflow is:

```bash
make
```

Check the services:

```bash
docker ps
```

Check WordPress:

```bash
docker exec wordpress wp core is-installed --allow-root
```

Check the users:

```bash
docker exec wordpress wp user list --allow-root
```

Check logs when needed:

```bash
docker logs wordpress
docker logs nginx
docker logs mariadb
```

For an HTTPS test inside the VM:

```bash
curl -kI https://tavdiiev.42.fr/
```

For an HTTPS test from the school host:

```bash
curl -kI -H "Host: tavdiiev.42.fr" https://127.0.0.1:8443/
```

## Important Project Constraints

The project should maintain the following architecture:

* NGINX is the only public entry point.
* NGINX listens on HTTPS port 443.
* TLS 1.2 and TLS 1.3 are enabled.
* WordPress/PHP-FPM is internal.
* MariaDB is internal.
* Services communicate through the `inception` Docker bridge network.
* Service names are used for internal communication.
* No host networking is required.
* No hard-coded container IP addresses are required.
* No passwords are stored in Dockerfiles or committed to Git.
* Use Docker secrets for passwords.
* Use the project's defined named volumes and required host storage layout.
* Do not replace the required persistence mechanism with unrelated storage.
* Do not use `latest` as a base-image tag.
* Do not expose MariaDB or PHP-FPM through published host ports.
* Keep the canonical WordPress URL as `https://tavdiiev.42.fr`.
* Do not add the school-only VirtualBox port `8443` to the final WordPress URL.

## Quick Reference

| **Action**                   | **Command**                                                  |
| ---------------------------- | ------------------------------------------------------------ |
| Start                        | `make`                                                       |
| Build and start              | `make build`                                                 |
| Stop                         | `make down`                                                  |
| Rebuild                      | `make re`                                                    |
| Check containers             | `docker ps`                                                  |
| Check all containers         | `docker ps -a`                                               |
| Check network                | `docker network inspect inception`                           |
| NGINX logs                   | `docker logs nginx`                                          |
| WordPress logs               | `docker logs wordpress`                                      |
| MariaDB logs                 | `docker logs mariadb`                                        |
| Check WordPress installation | `docker exec wordpress wp core is-installed --allow-root`    |
| Check WordPress version      | `docker exec wordpress wp core version --allow-root`         |
| List WordPress users         | `docker exec wordpress wp user list --allow-root`            |
| Test HTTPS from VM           | `curl -kI https://tavdiiev.42.fr/`                           |
| Test HTTPS from school host  | `curl -kI -H "Host: tavdiiev.42.fr" https://127.0.0.1:8443/` |
