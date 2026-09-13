
*This project has been created as part of the 42 curriculum by tavdiiev.*

# Inception

A small WordPress infrastructure built from scratch with Docker and orchestrated by Docker Compose. The stack consists of NGINX, WordPress with PHP-FPM, and MariaDB, with HTTPS handled by NGINX and persistent data stored using Docker volumes. Each service is built locally from an Alpine Linux base image, with the containers communicating through a dedicated Docker bridge network.

## Description

Inception is a system administration and Docker project from the 42 curriculum. The goal of the project is to build a small multi-container infrastructure using Docker Compose, while understanding how the individual services communicate and how persistent data, networking, security, and configuration are handled.

The infrastructure consists of three main services:

- **NGINX** — the only publicly accessible entry point. It handles HTTPS connections on port 443 and forwards PHP requests to WordPress through FastCGI.
- **WordPress with PHP-FPM** — provides the WordPress application and executes PHP code through PHP-FPM.
- **MariaDB** — provides the database used by WordPress.

The resulting architecture is:


                        HTTPS :443

                              │

                              ▼

                       ┌─────────┐
                       │  NGINX  │
                       └────┬────┘
                            │
                       FastCGI :9000
                            │
                            ▼

                     ┌──────────────┐
                     │   WordPress  │
                     │   PHP-FPM    │
                     └──────┬───────┘
                            │
                       MySQL :3306
                            │
                            ▼

                       ┌──────────┐
                       │ MariaDB  │
                       └──────────┘

                 Docker bridge network: inception


Only NGINX is exposed outside the Docker network. WordPress/PHP-FPM and MariaDB communicate internally through the Docker bridge network.

### Docker

Docker is used to isolate each major service in its own container. Each container contains the software required for its service, while Docker Compose defines how the containers are built, connected, configured, and started.

The project uses custom Dockerfiles rather than relying on preconfigured application images. The services are based on Alpine Linux 3.23.

The project uses:

* Dockerfiles for building the service images.
* Docker Compose for orchestration.
* A user-defined Docker bridge network for communication between containers.
* Docker secrets for database and WordPress passwords.
* Named Docker volumes for persistent WordPress and MariaDB data.
* HTTPS/TLS 1.2 and TLS 1.3 for the public NGINX endpoint.
* WP-CLI for automatic WordPress installation and user creation.

### Sources included in the project

The project is divided into several components:

```text
srcs/
├── docker-compose.yml
├── .env
└── requirements/
    ├── nginx/
    │   ├── Dockerfile
    │   ├── conf/
    │   └── tools/
    │
    ├── wordpress/
    │   ├── Dockerfile
    │   ├── conf/
    │   └── tools/
    │
    └── mariadb/
        ├── Dockerfile
        ├── conf/
        └── tools/
```

The NGINX source files configure HTTPS, certificates, PHP request forwarding, and WordPress routing.

The WordPress source files install the required PHP packages and WP-CLI, generate `wp-config.php`, automatically install WordPress when necessary, create the configured WordPress users, configure PHP-FPM, and start PHP-FPM.

The MariaDB source files install and initialize MariaDB, create the WordPress database and database user, configure privileges, and start the MariaDB server.

Sensitive passwords are not stored in the Dockerfiles or Git repository. They are provided through Docker secrets.

## Design Choices

### Multi-container architecture

Each major service runs in its own container instead of putting the entire application stack into a single container.

This provides clear separation of responsibilities:

* NGINX handles incoming HTTPS traffic.
* WordPress/PHP-FPM handles application code.
* MariaDB handles database operations.

The services communicate through the Docker network using service names such as:

```text
nginx → wordpress:9000
wordpress → mariadb:3306
```

The containers do not need hard-coded IP addresses because Docker provides internal DNS resolution for services on the same network.

### HTTPS

NGINX is configured as the public entry point:

```nginx
listen 443 ssl;
```

Only port 443 is published by Docker Compose:

```yaml
ports:
  - "443:443"
```

TLS 1.2 and TLS 1.3 are enabled. The TLS certificate and private key are mounted into the NGINX container.

PHP-FPM and MariaDB are not published to the outside world because they only need to communicate internally.

The configured WordPress URL is:

```text
https://tavdiiev.42.fr
```

In the school virtual-machine environment, VirtualBox may forward host port 8443 to the VM's port 443 for testing. Port 8443 is only a host-side forwarding port and is not part of the project's configured WordPress URL.

### Base images

The containers use Alpine Linux 3.23 as the base image.

Using a lightweight distribution keeps the images relatively small while providing the packages required by NGINX, PHP-FPM, WordPress, and MariaDB.

## Virtual Machines vs Docker

A virtual machine emulates or virtualizes an entire computer environment. It normally contains its own operating system kernel and system environment.

Docker containers instead share the host operating system's kernel while isolating applications and their dependencies.

| **Virtual Machines**                           | **Docker**                                      |
| ---------------------------------------------- | ----------------------------------------------- |
| Virtualizes a complete machine                 | Isolates applications/processes                 |
| Usually includes a complete guest OS           | Containers share the host kernel                |
| Generally heavier                              | Generally lighter                               |
| Usually slower to start                        | Usually starts quickly                          |
| Strong hardware/OS-level isolation             | Process and namespace-based isolation           |
| Useful for running different operating systems | Useful for packaging and deploying applications |

For this project, Docker is appropriate because the goal is to isolate the individual services while keeping the infrastructure lightweight and reproducible.

The Debian virtual machine used during development provides an isolated environment in which Docker itself runs. Docker then provides another layer of isolation for the project services.

## Secrets vs Environment Variables

Environment variables are convenient for passing configuration values to containers. They are suitable for non-sensitive configuration such as:

```env
DB_NAME=wordpress
DB_USER=wpuser
DOMAIN_NAME=tavdiiev.42.fr
WP_TITLE=Inception
WP_ADMIN_USER=tavd_user1
WP_ADMIN_EMAIL=some_email@gmail.com
WP_USER=tavd_user2
WP_USER_EMAIL=some_email2@gmail.com
WP_URL=https://tavdiiev.42.fr
```

Passwords should not be treated as ordinary configuration.

This project therefore uses Docker secrets for database and WordPress passwords:

```text
/run/secrets/db_password
/run/secrets/db_root_password
/run/secrets/wp_admin_password
/run/secrets/wp_user_password
```

The secret files have the following purposes:

* `db_password.txt` — password of the MariaDB database user used by WordPress.
* `db_root_password.txt` — MariaDB root password.
* `wp_admin_password.txt` — WordPress administrator password.
* `wp_user_password.txt` — normal/subscriber WordPress user password.

| **Secrets**                                                | **Environment Variables**                |
| ---------------------------------------------------------- | ---------------------------------------- |
| Intended for sensitive information                         | Mainly configuration                     |
| Mounted as files inside the container                      | Exposed through the process environment  |
| Better suited for passwords                                | Convenient for ordinary settings         |
| Avoids putting passwords directly in Compose configuration | Can expose sensitive values more broadly |

In this project, database names, usernames, WordPress settings, and other non-sensitive configuration values are passed through environment variables, while passwords are provided through Docker secrets.

## Docker Network vs Host Network

The project uses a user-defined Docker bridge network:

```yaml
networks:
  inception:
    driver: bridge
```

All three services are connected to this network.

This allows containers to communicate privately using Docker's internal DNS:

```text
NGINX
  │
  └── wordpress:9000

WordPress
  │
  └── mariadb:3306
```

A host network would instead make a container use the host's network stack directly.

| **Docker Network**                                      | **Host Network**                                              |
| ------------------------------------------------------- | ------------------------------------------------------------- |
| Provides network isolation                              | Shares the host network namespace                             |
| Containers receive their own network identity           | Container uses host networking                                |
| Services can communicate using Docker DNS/service names | Docker service-name networking is not used in the same way    |
| Ports can be explicitly published                       | Container ports are directly associated with the host network |
| Better separation between services                      | Less network isolation                                        |

The Docker bridge network was chosen because the services only need to communicate with each other and should not require direct access to the host network.

Only NGINX needs to be accessible from outside the Docker network.

## Docker Volumes vs Bind Mounts

Persistent data must survive container recreation. The project therefore uses Docker named volumes for WordPress and MariaDB data.

The Compose configuration defines:

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

The Docker volumes are mounted inside the containers at:

```text
WordPress → /var/www/
MariaDB   → /var/lib/mysql
```

This means that destroying and recreating the containers does not automatically destroy the persistent application/database data.

| **Docker Volumes**                                          | **Bind Mounts**                             |
| ----------------------------------------------------------- | ------------------------------------------- |
| Managed through Docker's volume system                      | Directly maps a host path                   |
| Docker controls the volume abstraction                      | User explicitly chooses the host directory  |
| Convenient for container data                               | Useful when exact host location is required |
| Portable between environments when configured appropriately | More dependent on host filesystem structure |

In this project, Docker named volumes are used as the container-facing storage mechanism, with their storage backed by the required directories under `/home/${USER}/data/`.

This combines the Docker volume abstraction with the required persistent host locations.

## Automatic WordPress Installation

WordPress installation is automated and does not require manually opening the WordPress installation page.

When the WordPress container starts, `wp.sh`:

1. Creates `wp-config.php` if it does not already exist.
2. Waits for MariaDB to become available.
3. Checks whether WordPress is already installed.
4. Installs WordPress with WP-CLI if it is not installed.
5. Creates the configured administrator account.
6. Creates the configured normal/subscriber user.
7. Starts PHP-FPM in the foreground.

WP-CLI is installed in the WordPress image and is used by the startup script.

If WordPress is already installed in the persistent volume, the installation is skipped. This prevents duplicate users and repeated installation when the container is recreated.

The installation can be checked with:

```bash
docker exec wordpress wp core is-installed --allow-root
```

To check the WordPress version:

```bash
docker exec wordpress wp core version --allow-root
```

To list the WordPress users:

```bash
docker exec wordpress wp user list --allow-root
```

## Instructions

### Requirements

The following software is required:

* Docker
* Docker Compose
* Git
* Bash
* A Linux environment capable of running Docker

### Clone the repository

Clone the repository and enter the project directory:

```bash
git clone <repository-url>
cd inception
```

### Configure the environment

The Compose configuration uses `srcs/.env` for non-sensitive configuration.

A typical configuration contains:

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

The local `.env` file is environment-specific and must not be committed to the repository.

The TLS certificate and private key are also environment-specific files and must be provided locally.

The project expects these secret files:

```text
secrets/
├── db_password.txt
├── db_root_password.txt
├── wp_admin_password.txt
└── wp_user_password.txt
```

These files must not be committed to Git.

### Build and start the infrastructure

To build the images and start the services:

```bash
make build
```

To start the already-built infrastructure:

```bash
make
```

or:

```bash
make all
```

The services are started in detached mode.

On a first startup with empty persistent data, MariaDB is initialized and WordPress is installed automatically.

### Check the containers

```bash
docker ps
```

The expected services are:

```text
nginx
wordpress
mariadb
```

### Access WordPress

The public entry point is NGINX over HTTPS:

```text
https://tavdiiev.42.fr/
```

Only NGINX is exposed through port 443.

### School virtual-machine testing

When the project is running inside the school Debian virtual machine, VirtualBox may forward:

```text
Host 127.0.0.1:8443 → VM port 443
```

The project itself still uses HTTPS port 443 and the configured WordPress URL remains:

```text
https://tavdiiev.42.fr
```

For a clean test from the school host, use:

```bash
curl -kI -H "Host: tavdiiev.42.fr" https://127.0.0.1:8443/
```

A successful `HTTP/1.1 200 OK` response confirms that the request reaches NGINX through the forwarded port and is served by WordPress.

### Stop the infrastructure

```bash
make down
```

This stops and removes the Compose containers and network while normally preserving the named volumes and persistent data.

### Rebuild the infrastructure

```bash
make re
```

This stops the current Compose infrastructure and then rebuilds and starts the services.

### Clean project data

The Makefile also provides:

```bash
make clean
```

and:

```bash
make fclean
```

These commands perform more extensive Docker cleanup and may remove persistent project data.

**Use them with caution**, especially `fclean`, because persistent WordPress and MariaDB data may be deleted.

## Makefile Commands

| **Command**   | **Purpose**                                |
| ------------- | ------------------------------------------ |
| `make`        | Start the existing configuration           |
| `make all`    | Start the existing configuration           |
| `make build`  | Build images and start containers          |
| `make down`   | Stop and remove Compose containers/network |
| `make re`     | Stop, rebuild, and restart                 |
| `make clean`  | Stop and clean project resources/data      |
| `make fclean` | Perform a more extensive Docker cleanup    |

## Data Persistence

The project stores persistent data outside the containers:

```text
/home/<user>/data/
├── wordpress/
└── mariadb/
```

WordPress files are stored through the `wp-volume` volume, while MariaDB data is stored through the `db-volume` volume.

The named volumes use the required host directories as their backing storage.

This is important because containers are considered disposable. Recreating a container should not automatically mean losing the application or database data.

The WordPress configuration file is also created only when it does not already exist:

```text
/var/www/wp-config.php
```

This prevents the startup script from overwriting an existing configuration stored in persistent storage.

## Service Startup

The WordPress container starts using a small shell script:

```text
wp.sh
    │
    ├── creates wp-config.php if necessary
    │
    ├── waits for MariaDB
    │
    ├── checks WordPress installation status
    │
    ├── installs WordPress if necessary
    │
    ├── creates the configured WordPress users
    │
    └── starts PHP-FPM in the foreground
```

The MariaDB container similarly initializes the database only when the persistent database has not already been initialized.

This allows the containers to be recreated without repeating the complete database initialization every time.

## Resources

### Official documentation

* Docker documentation: https://docs.docker.com/
* Docker Compose documentation: https://docs.docker.com/compose/
* Docker networking documentation: https://docs.docker.com/engine/network/
* Docker volumes documentation: https://docs.docker.com/engine/storage/volumes/
* Docker secrets documentation: https://docs.docker.com/engine/swarm/secrets/
* NGINX documentation: https://nginx.org/en/docs/
* PHP-FPM documentation: https://www.php.net/manual/en/install.fpm.php
* WordPress documentation: https://developer.wordpress.org/
* MariaDB documentation: https://mariadb.com/docs/
* Alpine Linux documentation: https://docs.alpinelinux.org/

### Additional references

The project also relies on general knowledge about:

* Linux processes and permissions
* Shell scripting
* HTTP and HTTPS
* TLS
* FastCGI
* MySQL/MariaDB databases
* Docker networking
* Docker image construction
* Docker Compose
* Persistent storage
* WP-CLI

### AI usage

AI tools were used as a learning and development aid during the project.

They were used primarily for:

* Explaining Docker and Docker Compose concepts.
* Understanding container networking, port publishing, bridge networks, and Docker DNS.
* Explaining NGINX configuration and HTTPS/TLS concepts.
* Understanding the relationship between NGINX, PHP-FPM, WordPress, and MariaDB.
* Explaining Docker volumes, bind mounts, environment variables, and Docker secrets.
* Understanding shell scripting syntax and Makefile syntax.
* Troubleshooting configuration and runtime issues.
* Reviewing and explaining project files and commands.
* Checking understanding of the project architecture and helping identify possible configuration issues.

AI was used as a support and explanation tool rather than as a replacement for understanding the project. The final configuration and implementation were tested in the project's Docker environment.

````

### `DEV_DOC.md`

I also reconstructed this from the latest version of the developer documentation and the project changes we made:

```markdown
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
````

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

````

### `USER_DOC.md`

```markdown
# Inception — User Documentation

## Overview

This project provides a WordPress website running as a Docker-based infrastructure.

The stack consists of three services:

- **NGINX** — receives HTTPS requests from the browser and serves as the public entry point.
- **WordPress with PHP-FPM** — runs the WordPress application and processes PHP code.
- **MariaDB** — stores the WordPress database.

The services communicate through a private Docker network.

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
````

Only NGINX is exposed to the outside. WordPress/PHP-FPM and MariaDB are used internally by the stack.

## Starting the Project

From the root of the repository, run:

```bash
make
```

This creates the required persistent-data directories if necessary and starts the Docker Compose infrastructure in detached mode.

When the WordPress container starts, the project automatically:

* waits for MariaDB to become available;
* creates `wp-config.php` if it does not already exist;
* checks whether WordPress is already installed;
* installs WordPress automatically if it is not installed;
* creates the configured WordPress administrator account;
* creates the configured normal/subscriber user;
* starts PHP-FPM in the foreground.

If WordPress is already installed, the installation steps are skipped and the existing installation is kept.

If the Docker images need to be rebuilt, use:

```bash
make build
```

After starting the project, check that the containers are running:

```bash
docker ps
```

You should see containers for:

* `nginx`
* `wordpress`
* `mariadb`

## Stopping the Project

To stop the project:

```bash
make down
```

This stops and removes the Docker Compose containers and network.

The persistent WordPress and MariaDB data is normally kept when using `make down`.

## Accessing the Website

The website is served through NGINX using HTTPS.

The configured project URL is:

```text
https://tavdiiev.42.fr/
```

NGINX listens on HTTPS port `443`.

In the school virtual-machine environment, VirtualBox forwards host port `8443` to the VM's HTTPS port `443`. Therefore, `8443` is only a local port-forwarding mechanism and is not part of the project's configured WordPress URL.

The project configuration keeps:

```text
WP_URL=https://tavdiiev.42.fr
```

without `:8443`.

NGINX handles the HTTPS connection and forwards PHP requests to the WordPress container.

### School host browser access

When testing from the school host machine, the VirtualBox forwarding configuration may use:

```text
Host 127.0.0.1:8443
        │
        ▼
VM port 443
        │
        ▼
NGINX
```

Because WordPress uses the canonical URL `https://tavdiiev.42.fr`, opening the forwarded `:8443` URL in a browser may cause WordPress to redirect to the standard HTTPS URL without `:8443`.

For a clean test from the school host, use:

```bash
curl -kI -H "Host: tavdiiev.42.fr" https://127.0.0.1:8443/
```

A successful response such as `HTTP/1.1 200 OK` confirms that the request reaches NGINX through the VirtualBox forwarding port and is served by WordPress.

If browser access through `:8443` specifically needs to be tested, the WordPress `home` and `siteurl` options can temporarily be changed to include `:8443`. After the browser test, both values should be restored to:

```text
https://tavdiiev.42.fr
```

Do not add `:8443` to `WP_URL` in the project's final configuration.

## Accessing the Administration Panel

The WordPress administration panel is available at:

```text
https://tavdiiev.42.fr/wp-admin/
```

The administrator account is created automatically when WordPress is installed for the first time.

Log in using the WordPress administrator username and password configured for the project.

The WordPress administrator account is separate from the MariaDB database account.

When testing through the school host's VirtualBox `:8443` forwarding port, the browser may redirect to the canonical URL without `:8443`. See **School host browser access** above for the recommended testing method.

## Credentials

There are two different groups of credentials used by the infrastructure: database credentials and WordPress credentials.

### Database credentials

Database passwords are stored as Docker secrets rather than being placed directly in the Docker Compose file or Dockerfiles.

The database secret files are:

* `secrets/db_password.txt`
* `secrets/db_root_password.txt`

Their purposes are:

* `db_password.txt` — password of the MariaDB user used by WordPress.
* `db_root_password.txt` — password of the MariaDB root user.

These files contain sensitive information and must not be committed to the Git repository.

### WordPress credentials

WordPress credentials are also supplied through Docker secrets and environment variables.

The WordPress password secret files are:

* `secrets/wp_admin_password.txt`
* `secrets/wp_user_password.txt`

Their purposes are:

* `wp_admin_password.txt` — password for the WordPress administrator account.
* `wp_user_password.txt` — password for the normal/subscriber WordPress user.

The usernames and other WordPress settings are configured through the project's `srcs/.env` file.

For example:

```text
WP_ADMIN_USER=tavd_user1
WP_ADMIN_EMAIL=some_email@gmail.com
WP_USER=tavd_user2
WP_USER_EMAIL=some_email2@gmail.com
```

During the first startup, WP-CLI uses these values and the Docker secrets to install WordPress and create the two WordPress accounts automatically.

The WordPress administrator password is not the same thing as the MariaDB root password or the WordPress database user's password.

All secret files and the local `.env` file contain sensitive or environment-specific information and must not be committed to the Git repository.

## Checking That WordPress Was Installed

The automatic WordPress installation can be checked with:

```bash
docker exec wordpress wp core is-installed --allow-root
```

If WordPress is installed, the command exits successfully.

To check the installed WordPress version:

```bash
docker exec wordpress wp core version --allow-root
```

To list the WordPress users:

```bash
docker exec wordpress wp user list --allow-root
```

The user list should contain the automatically created administrator and normal/subscriber user.

## Checking That the Services Are Running

Use:

```bash
docker ps
```

to see the running containers.

You should see the three project services:

* `nginx`
* `wordpress`
* `mariadb`

To see all containers, including stopped ones:

```bash
docker ps -a
```

### Checking the logs

**NGINX logs:**

```bash
docker logs nginx
```

**WordPress/PHP-FPM logs:**

```bash
docker logs wordpress
```

**MariaDB logs:**

```bash
docker logs mariadb
```

The WordPress logs also show whether the automatic installation was performed or skipped.

On a fresh WordPress data directory, the logs should contain messages similar to:

```text
WordPress is not installed. Installing...

Success: WordPress installed successfully.

Success: Created user 2.
```

When WordPress is already installed, the installation is skipped and the logs contain:

```text
WordPress is already installed.
```

### Checking the services individually

You can check the NGINX container with:

```bash
docker inspect nginx
```

You can check the WordPress container with:

```bash
docker inspect wordpress
```

You can check the MariaDB container with:

```bash
docker inspect mariadb
```

These commands show information such as the container state, network configuration, mounts, and other Docker configuration.

## Checking Persistent Data

The project uses persistent storage for WordPress and MariaDB.

The required host storage directories are:

```text
/home/<user>/data/
├── wordpress/
└── mariadb/
```

The exact `<user>` is the Linux user running the project.

The project defines named Docker volumes for WordPress and MariaDB. Their storage is backed by the required host directories above.

The WordPress data is mounted into the container at:

```text
/var/www/
```

MariaDB data is mounted at:

```text
/var/lib/mysql/
```

This allows the data to survive normal container recreation.

## Important Warning

**Do not use commands that remove Docker volumes or delete the data directories unless you intentionally want to reset the project.**

In particular, commands such as:

```bash
docker-compose down -v
```

or the project's full-clean command can remove persistent data.

Removing the MariaDB data can result in losing the WordPress database and its users/settings.

## Quick Reference

| **Action**                   | **Command**                                                  |
| ---------------------------- | ------------------------------------------------------------ |
| Start                        | `make`                                                       |
| Build and start              | `make build`                                                 |
| Stop                         | `make down`                                                  |
| Rebuild                      | `make re`                                                    |
| Check running containers     | `docker ps`                                                  |
| Check all containers         | `docker ps -a`                                               |
| Check WordPress installation | `docker exec wordpress wp core is-installed --allow-root`    |
| Check WordPress version      | `docker exec wordpress wp core version --allow-root`         |
| List WordPress users         | `docker exec wordpress wp user list --allow-root`            |
| NGINX logs                   | `docker logs nginx`                                          |
| WordPress logs               | `docker logs wordpress`                                      |
| MariaDB logs                 | `docker logs mariadb`                                        |
| VM HTTPS test                | `curl -kI https://tavdiiev.42.fr/`                           |
| School host HTTPS test       | `curl -kI -H "Host: tavdiiev.42.fr" https://127.0.0.1:8443/` |
| Website                      | `https://tavdiiev.42.fr/`                                    |
| WordPress admin              | `https://tavdiiev.42.fr/wp-admin/`                           |

````

**Important:** I put each complete file inside an outer code fence in the writing block. The **content inside those fences is the exact Markdown you should put into the corresponding GitHub file**. In particular, the file should contain `### AI usage`, `**NGINX**`, ` ```bash`, etc. — **not** the backslash-escaped versions from your earlier messages.
````
