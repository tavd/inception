*This project has been created as part of the 42 curriculum by tavdiiev.*

# Inception

A small WordPress infrastructure built from scratch with Docker and orchestrated by Docker Compose. The stack consists of NGINX, WordPress with PHP-FPM, and MariaDB, with HTTPS handled by NGINX and persistent data stored using Docker volumes. Each service is built locally from an Alpine Linux base image, with the containers communicating through a dedicated Docker bridge network.

## Description

Inception is a system administration and Docker project from the 42 curriculum. The goal of the project is to build a small multi-container infrastructure using Docker Compose, while understanding how the individual services communicate and how persistent data, networking, security, and configuration are handled.

The infrastructure consists of three main services:

* **NGINX** — the only publicly accessible entry point. It handles HTTPS connections on port 443 and forwards PHP requests to WordPress through FastCGI.
* **WordPress with PHP-FPM** — provides the WordPress application and executes PHP code through PHP-FPM.
* **MariaDB** — provides the database used by WordPress.

The resulting architecture is:
```text
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
```
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
WP_ADMIN_USER=example_user
WP_ADMIN_EMAIL=example_user@example.com
WP_USER=example_user2
WP_USER_EMAIL=example_user2@example.com
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
* mkcert
* A Linux environment capable of running Docker
* A graphical desktop environment in the VM for browser-based testing

### Clone the repository

Clone the repository and enter the project directory:

```bash
git clone <repository-url>
cd inception
```
## Configure the environment

The repository provides an environment template at:
```text
srcs/.env.example
```
Copy it to `srcs/.env` and adjust the values for the local environment:
```bash
cp srcs/.env.example srcs/.env
```
The `.env` file contains non-sensitive configuration such as:
* domain name
* database name and user
* WordPress site title
* WordPress administrator and regular user names and email addresses
* canonical WordPress URL
Passwords are **not stored in** **`.env`**. They are provided separately through Docker secrets.
The repository provides example templates for the required secret files:
```text
secrets/
├── db_password.txt.example
├── db_root_password.txt.example
├── wp_admin_password.txt.example
└── wp_user_password.txt.example
```
Copy each example file to the corresponding secret file and replace the example value with the desired password:
```bash
cp secrets/db_password.txt.example secrets/db_password.txt
cp secrets/db_root_password.txt.example secrets/db_root_password.txt
cp secrets/wp_admin_password.txt.example secrets/wp_admin_password.txt
cp secrets/wp_user_password.txt.example secrets/wp_user_password.txt
```
The resulting files should be:
```text
srcs/.env
secrets/
├── db_password.txt
├── db_root_password.txt
├── wp_admin_password.txt
└── wp_user_password.txt
```

These local configuration and secret files are excluded from Git and must not be committed to the repository.

The NGINX HTTPS configuration also requires a local TLS certificate and private key. These files are excluded from Git and must be generated locally before starting the containers. See DEV_DOC.md for the certificate generation procedure using mkcert.

## Build and start the infrastructure

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
