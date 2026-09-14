# Inception — Developer Documentation

## Overview

This document explains the internal structure, configuration, build process, networking, persistence, security, and development workflow of the Inception project.

The project consists of three Docker services:

- **NGINX** — public HTTPS entry point.
- **WordPress/PHP-FPM** — application and PHP execution layer.
- **MariaDB** — database layer.

The services communicate through a private Docker bridge network named `inception`.

The architecture is:

```text
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
```

Only NGINX publishes a port. WordPress/PHP-FPM and MariaDB are internal services.

## Project Structure

```text
inception/
├── Makefile
├── README.md
├── USER_DOC.md
├── DEV_DOC.md
├── secrets/                           # git-ignored real credentials (one secret per file)
│   ├── db_password.txt
│   ├── db_root_password.txt
│   ├── wp_admin_password.txt
│   └── wp_user_password.txt
└── srcs/
    ├── .env                           # git-ignored non-secret
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   │   └── nginx.conf
        │   └── tools/                 # git-ignored
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
* mkcert
* A Linux environment capable of running Docker

The current project uses Alpine Linux 3.23 as the base image for all three services.

## Setting Up Environment From Scratch

After cloning the repository, the local environment-specific files must be created before the first build.

The real `.env` and secret files are excluded from Git:

```text
srcs/.env
secrets/*.txt
```

The repository contains tracked example templates that can be copied and renamed to create the required local files:

```text
srcs/.env.example
secrets/*.txt.example
```

The example files contain placeholders only and must be replaced with the real local values before starting the project.

### Clone the repository and enter the project directory:

```bash
git clone <repository-url>
cd <project-directory>
```

### 1. Create `srcs/.env` from the example

Copy the tracked environment template:

```bash
cp srcs/.env.example srcs/.env
```

Then edit `srcs/.env` and replace the example values with the values required for the local environment.

The template contains the variables expected by the project:

```dotenv
# Domain
DOMAIN_NAME=tavdiiev.42.fr

`DOMAIN_NAME` is set to `tavdiiev.42.fr` because this domain is used consistently throughout the project, including the NGINX configuration, TLS certificate, and local hosts configuration.

# MariaDB
DB_NAME=wordpress
DB_USER=wpuser

# WordPress
WP_TITLE=Inception
WP_ADMIN_USER=example_user
WP_ADMIN_EMAIL=example_user@example.com
WP_USER=example_user2
WP_USER_EMAIL=example_user2@example.com

# Canonical WordPress URL
WP_URL=https://tavdiiev.42.fr

This is the URL used by WordPress for the website. The VirtualBox forwarding port (`:8443`) is not included because it is only used to access the VM from the host machine.
```
> `WP_ADMIN_USER` must not contain `admin` or `administrator`, case-insensitively.
> Passwords are **not stored in** **`.env`**. They are provided separately through Docker secrets.
> Keep the variable names unchanged because they are used by the Docker Compose configuration and startup scripts.
> The canonical `WP_URL` must not contain the school VirtualBox forwarding port such as `:8443`. The project URL remains: `https://tavdiiev.42.fr`
> Port `8443` is only used as a host-side forwarding port in the school VirtualBox environment.
### 2. Create the secret files from the examples

The repository contains tracked templates for the four required Docker secrets:

```text
secrets/
├── db_password.txt.example
├── db_root_password.txt.example
├── wp_admin_password.txt.example
└── wp_user_password.txt.example
```

Copy all of the templates to their real filenames:

```bash
for f in secrets/*.txt.example; do cp "$f" "${f%.example}"; done
```

This creates:

```text
secrets/
├── db_password.txt
├── db_root_password.txt
├── wp_admin_password.txt
└── wp_user_password.txt
```

Edit each real secret file and replace its placeholder with the required value:

```text
secrets/db_root_password.txt
    → MariaDB root password

secrets/db_password.txt
    → MariaDB password for the WordPress database user

secrets/wp_admin_password.txt
    → WordPress administrator password

secrets/wp_user_password.txt
    → WordPress normal/subscriber user password
```

Each secret file should contain **only the raw secret value**:

```text
my_real_password
```

Do not add a variable name, label, quotes, or other text.

For example, do not write:

```text
DB_PASSWORD=my_real_password
```

The files are mounted by Docker as secrets under:

```text
/run/secrets/
```

and the project startup scripts read them from there.

A trailing newline in a secret file is harmless because the project reads the values using command substitution such as:

```sh
$(cat /run/secrets/db_password)
```

Command substitution removes trailing newline characters.

### 3. Create the local TLS certificate and private key

The NGINX configuration requires these two files:

```text
srcs/requirements/nginx/tools/tavdiiev.42.fr.crt
srcs/requirements/nginx/tools/tavdiiev.42.fr.key
```

These files are local environment-specific files and are excluded from Git because `.gitignore` ignores `*.crt` and `*.key` files.

Therefore, a fresh Git clone does not contain the certificate or private key.

Create the directory if it does not already exist:

```bash
mkdir -p srcs/requirements/nginx/tools
```

The project uses `mkcert` to create a local development certificate.

Check that `mkcert` is installed:

```bash
mkcert --version
```

Then change to the NGINX tools directory:

```bash
cd srcs/requirements/nginx/tools
```

Generate a certificate for the domain used by the project:

```bash
mkcert tavdiiev.42.fr
```

`mkcert` normally creates two files:

```text
tavdiiev.42.fr.pem
tavdiiev.42.fr-key.pem
```

Rename them to the filenames expected by the NGINX configuration:

```bash
mv tavdiiev.42.fr.pem tavdiiev.42.fr.crt
mv tavdiiev.42.fr-key.pem tavdiiev.42.fr.key
```

The directory should then contain:

```text
tavdiiev.42.fr.crt
tavdiiev.42.fr.key
```

The certificate and private key are mounted into the NGINX container by Docker Compose:

```yaml
- ./requirements/nginx/tools:/etc/nginx/ssl/
```

Inside the container, NGINX therefore uses:

```text
/etc/nginx/ssl/tavdiiev.42.fr.crt
/etc/nginx/ssl/tavdiiev.42.fr.key
```

These files must exist locally before starting the containers because NGINX needs them to configure HTTPS.

### 4. Verify the local files before building and starting

A fresh clone should contain the example templates but not the real credentials:

```text
srcs/.env.example
secrets/*.txt.example
```

After creating the local files, the working tree should contain:

```text
srcs/.env
secrets/db_password.txt
secrets/db_root_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
srcs/requirements/nginx/tools/tavdiiev.42.fr.crt
srcs/requirements/nginx/tools/tavdiiev.42.fr.key
```

These real files are ignored by Git.

You can verify this with:

```bash
git status --short --ignored
```

The real `.env` and secret files should appear as ignored files (`!!`).

The certificate and private key are inside the ignored `srcs/requirements/nginx/tools/` directory, which should also appear as an ignored path (`!!`).

### 5. Keeping the examples in sync

If a project variable or required secret is added or renamed, update the corresponding `*.example` template as well.

For example:

- adding a variable to `srcs/.env` → update `srcs/.env.example`
- adding a Docker secret → add the corresponding `secrets/*.txt.example`

The `.gitignore` is configured so that:

```text
srcs/.env
secrets/*.txt
```

remain excluded from Git, while:

```text
srcs/.env.example
secrets/*.txt.example
```

remain trackable.

This allows a fresh clone to contain everything needed to understand and reproduce the configuration without committing any real credentials.

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
