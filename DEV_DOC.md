# Inception — Developer Documentation

## Overview

This project implements a small Docker-based infrastructure running WordPress with PHP-FPM, MariaDB, and NGINX.

The infrastructure consists of three services:

* **NGINX** — the only public entry point. It handles HTTPS connections and forwards PHP requests to WordPress/PHP-FPM.
* **WordPress with PHP-FPM** — runs the WordPress application and processes PHP requests.
* **MariaDB** — stores the WordPress database.

The services run in separate Docker containers and communicate through a private Docker network.

The basic architecture is:

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

Only NGINX is exposed to the outside. WordPress/PHP-FPM and MariaDB are accessible internally through the Docker network.

The project must be run inside a virtual machine and uses Docker Compose to build and manage the infrastructure.

---

## Prerequisites

Before setting up the project, make sure the following are available inside the virtual machine:

* A supported Linux distribution, such as Debian.
* Docker.
* Docker Compose.
* Git.
* `make`.
* A shell such as `bash`.
* Sufficient disk space for Docker images and persistent WordPress/MariaDB data.

The project must be run inside a virtual machine as required by the Inception subject.

### Docker requirements

Docker must be running before using the Makefile.

Check that Docker is available with:

```bash
docker --version
```

Check Docker Compose with:

```bash
docker compose version
```

Check that Docker is running:

```bash
docker info
```

If Docker is not running, start the Docker service using the appropriate command for the virtual machine's Linux distribution.

---

## Project Structure

The project has the following general structure:

```text
inception/
├── Makefile
├── secrets/
│   ├── db_password.txt
│   └── db_root_password.txt
└── srcs/
    ├── .env
    ├── docker-compose.yml
    └── requirements/
        ├── mariadb/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        ├── wordpress/
        │   ├── Dockerfile
        │   ├── conf/
        │   └── tools/
        └── tools/
```

The exact contents of the `conf/` and `tools/` directories depend on the implementation of each service.

### Makefile

The `Makefile` provides the main commands used to build, start, stop, and rebuild the infrastructure.

### `srcs/docker-compose.yml`

This file defines:

* the three services;
* the Docker network;
* the persistent named volumes;
* build configurations;
* environment variables;
* Docker secrets;
* service dependencies;
* restart policies;
* exposed ports.

### `srcs/.env`

The `.env` file contains non-secret environment variables used by Docker Compose and the service configuration.

For example:

```text
DOMAIN_NAME=tavdiiev.42.fr
```

Other project-specific variables such as the MariaDB database name and username are also configured through environment variables.

Passwords and other confidential information must not be placed directly in this file when they are handled through Docker secrets.

### `secrets/`

The `secrets/` directory contains confidential information required by the database configuration.

The project uses:

```text
secrets/db_password.txt
secrets/db_root_password.txt
```

These files must remain local and must not be committed to Git.

---

## Setting Up the Environment From Scratch

### 1. Start the virtual machine

Start the Linux virtual machine used for the Inception project.

Open a terminal and make sure you are working inside the project directory.

For example:

```bash
cd ~/inception
```

### 2. Clone or copy the project

If the project is stored in a Git repository, clone it into the virtual machine:

```bash
git clone <repository>
cd inception
```

Do not commit passwords, credentials, API keys, or other confidential information to the repository.

### 3. Check the directory structure

From the project root:

```bash
ls -la
```

The project should contain at least:

```text
Makefile
secrets/
srcs/
```

Check the `srcs` directory:

```bash
ls -la srcs
```

It should contain:

```text
.env
docker-compose.yml
requirements/
```

### 4. Create the secrets

Create the database password secret:

```bash
nano secrets/db_password.txt
```

Enter the password that will be used by the WordPress database user.

Create the MariaDB root password secret:

```bash
nano secrets/db_root_password.txt
```

Enter the MariaDB root password.

The secret files should contain the passwords only, without unnecessary configuration syntax.

For example:

```text
my_database_password
```

and:

```text
my_root_password
```

The actual passwords must never be placed in the Dockerfiles or committed to Git.

### 5. Configure the `.env` file

Edit:

```bash
nano srcs/.env
```

The `.env` file contains the environment variables required by the Docker Compose configuration.

For example:

```text
DOMAIN_NAME=tavdiiev.42.fr
```

Database-related non-secret configuration should also be defined here according to the project's `docker-compose.yml`.

Passwords should be provided through Docker secrets rather than hard-coded into Dockerfiles or Compose configuration.

### 6. Configure the domain name

The project domain must follow the required format:

```text
<login>.42.fr
```

For this project:

```text
tavdiiev.42.fr
```

The domain must resolve to the IP address through which the NGINX container can be reached.

In a normal environment, configure the appropriate hosts/DNS entry so that:

```text
tavdiiev.42.fr
```

resolves to the local IP address used to access the infrastructure.

Verify the configuration with an appropriate DNS or hosts lookup command.

### 7. Check the Docker configuration

Before building the project, inspect:

```text
srcs/docker-compose.yml
```

and verify that:

* all three services are defined;
* each service has its own Dockerfile;
* the services use the required build contexts;
* the `inception` network is defined;
* the two persistent named volumes are defined;
* Docker secrets are configured;
* environment variables are loaded from `.env`;
* NGINX is the only service exposed externally;
* NGINX uses port `443`;
* the containers have restart policies;
* no `network: host` or Docker links are used.

---

## School Environment and Browser Access

The Inception project runs inside a Debian virtual machine.

In the school environment, the host computer may not allow modification of the system `/etc/hosts` file. In that situation, the domain:

```text
tavdiiev.42.fr
```

cannot necessarily be resolved normally by the browser.

A separate Chrome profile can be started with a temporary host-resolution rule that maps the project domain to the local machine.

### Start Chrome with the project domain mapped locally

From the host machine, use:

```bash
google-chrome --user-data-dir=/tmp/chrome-test --host-resolver-rules="MAP tavdiiev.42.fr 127.0.0.1"
```

This starts Chrome with a separate temporary profile and tells Chrome to resolve:

```text
tavdiiev.42.fr
```

to:

```text
127.0.0.1
```

This does not modify the system-wide hosts file.

### Access the website

When using the VirtualBox port forwarding configured for the school environment, open:

```text
https://tavdiiev.42.fr:8443/
```

The administrator area is:

```text
https://tavdiiev.42.fr:8443/wp-admin/
```

The `8443` port is the host-side VirtualBox forwarding port.

The Inception NGINX container itself still listens on:

```text
443
```

The connection path is:

```text
School PC
    │
    │ https://tavdiiev.42.fr:8443/
    ▼
127.0.0.1:8443
    │
    │ VirtualBox port forwarding
    ▼
Debian VM :443
    │
    ▼
NGINX :443
    │
    │ FastCGI :9000
    ▼
WordPress / PHP-FPM
    │
    │ MySQL :3306
    ▼
MariaDB
```

Therefore, `8443` is only the VirtualBox host-side forwarding port used to reach the VM from the school computer. The project's actual HTTPS entry point remains NGINX on port `443`.

### Important distinction

The following two ports have different purposes:

```text
443
```

is the HTTPS port used by NGINX inside the Inception infrastructure.

```text
8443
```

is the host-side VirtualBox forwarding port used to reach the VM from the school computer.

The project itself must not be changed to use `8443` as its NGINX port merely because VirtualBox forwards the host's `8443` port to the VM's `443` port.

---

## Initial WordPress Installation

When the project is started for the first time with empty persistent WordPress and MariaDB data, WordPress needs to be initialized.

The exact first-start behavior should be verified in a clean clone/environment because existing persistent volumes can preserve an earlier WordPress installation.

### 1. Start the infrastructure

From the project root:

```bash
make
```

Check that the containers are running:

```bash
docker ps
```

The three project containers should be running:

```text
nginx
wordpress
mariadb
```

### 2. Start Chrome with the local domain mapping

On the school host computer:

```bash
google-chrome --user-data-dir=/tmp/chrome-test --host-resolver-rules="MAP tavdiiev.42.fr 127.0.0.1"
```

### 3. Open the WordPress administrator URL

Open:

```text
https://tavdiiev.42.fr:8443/wp-admin/
```

If the WordPress data is empty and the automatic WordPress configuration has not already completed the installation, the WordPress installation page should appear.

The installation page can then be used to create the first WordPress administrator account.

### 4. Create the WordPress administrator

Create the administrator account using the WordPress installation form.

The administrator username must comply with the Inception requirements.

In particular, it must not contain:

```text
admin
```

or:

```text
administrator
```

including prohibited capitalization or equivalent variations.

The WordPress administrator password should be stored securely.

### 5. Log in to the WordPress dashboard

After completing the installation, log in through:

```text
https://tavdiiev.42.fr:8443/wp-admin/
```

The WordPress dashboard should then be available.

### 6. Create a normal WordPress user

From the WordPress dashboard, create a second, normal user account if required for testing the two-user database requirement.

The administrator account and normal user account should be separate accounts.

### Important note about persistent volumes

WordPress installation state is stored in the persistent volumes.

If WordPress has already been initialized, visiting:

```text
https://tavdiiev.42.fr:8443/wp-admin/
```

will normally lead to the existing WordPress installation rather than displaying the initial installation form.

Removing and recreating containers with:

```bash
make down
```

does not normally remove the persistent volumes.

A completely fresh WordPress installation therefore requires intentionally resetting the persistent WordPress and MariaDB data.

Do not remove the volumes merely to test the installation unless losing the existing database and website data is acceptable.

---

## Building the Project

The project images are built from the project's own Dockerfiles.

Ready-made application images must not be pulled for the project services.

The base images are based on the required stable Alpine/Debian version specified by the project implementation.

From the project root, build and start the infrastructure with:

```bash
make
```

If the images need to be explicitly rebuilt, use:

```bash
make build
```

The Makefile invokes Docker Compose, which builds the Dockerfiles for:

```text
nginx
wordpress
mariadb
```

The resulting Docker images correspond to the project services.

### Check the built images

Use:

```bash
docker images
```

or:

```bash
docker image ls
```

This can be used to verify that the project images have been created.

---

## Launching the Project

The normal way to launch the infrastructure is:

```bash
make
```

The Makefile starts Docker Compose in detached mode.

After starting the project, check the containers:

```bash
docker ps
```

The three project containers should be running:

```text
nginx
wordpress
mariadb
```

The containers should restart automatically if they stop because of a crash, according to the restart policy configured in `docker-compose.yml`.

---

## Checking the Docker Network

The three services communicate through the project's private Docker network.

List Docker networks:

```bash
docker network ls
```

The project network is:

```text
inception
```

Inspect the network:

```bash
docker network inspect inception
```

The NGINX, WordPress, and MariaDB containers should be connected to this network.

Service names are used for communication between containers.

For example, NGINX forwards PHP requests to:

```text
wordpress:9000
```

WordPress connects to MariaDB through:

```text
mariadb:3306
```

The containers do not need to communicate through host IP addresses.

---

## Managing Containers

### Check running containers

```bash
docker ps
```

### Check all containers

To include stopped containers:

```bash
docker ps -a
```

### View container logs

NGINX:

```bash
docker logs nginx
```

WordPress:

```bash
docker logs wordpress
```

MariaDB:

```bash
docker logs mariadb
```

To follow logs continuously:

```bash
docker logs -f nginx
```

or:

```bash
docker logs -f wordpress
```

or:

```bash
docker logs -f mariadb
```

Press `Ctrl + C` to stop following the logs.

### Inspect a container

NGINX:

```bash
docker inspect nginx
```

WordPress:

```bash
docker inspect wordpress
```

MariaDB:

```bash
docker inspect mariadb
```

These commands can be useful for checking:

* container state;
* network configuration;
* mounts;
* environment configuration;
* restart policies;
* other Docker configuration.

### Open a shell inside a container

When troubleshooting, a shell can be opened inside a running container if the required shell is available.

For example:

```bash
docker exec -it nginx sh
```

or:

```bash
docker exec -it wordpress sh
```

or:

```bash
docker exec -it mariadb sh
```

Use `exit` to leave the container shell.

---

## Managing the Project With the Makefile

The Makefile is the preferred way to manage the project.

### Start the project

```bash
make
```

### Build the project

```bash
make build
```

This rebuilds the Docker images and starts the infrastructure according to the Makefile.

### Stop the project

```bash
make down
```

This stops and removes the Docker Compose containers and network.

The persistent named volumes are normally kept.

### Rebuild the project

```bash
make re
```

This target is used to rebuild/recreate the project according to the Makefile configuration.

The exact sequence is defined by the project's Makefile.

---

## Managing Docker Compose Directly

Docker Compose can also be used directly from the `srcs` directory when troubleshooting or inspecting the configuration.

For example:

```bash
cd srcs
```

Then:

```bash
docker compose up -d
```

To rebuild the images:

```bash
docker compose up -d --build
```

To stop the Compose project:

```bash
docker compose down
```

The Makefile should normally be preferred because it provides the project's intended workflow.

---

## Managing Volumes

The project uses two Docker named volumes for persistent storage.

The volumes are:

* WordPress files.
* MariaDB database files.

List Docker volumes:

```bash
docker volume ls
```

Inspect a volume:

```bash
docker volume inspect <volume_name>
```

The exact Docker volume names depend on the Compose project configuration.

The volumes are mounted inside the containers at:

```text
/var/www/
```

for WordPress files, and:

```text
/var/lib/mysql/
```

for MariaDB data.

### Important: Do Not Remove the Volumes Accidentally

The persistent data must survive normal container recreation.

Do not use:

```bash
docker compose down -v
```

unless you intentionally want to remove the project's named volumes.

Likewise, do not manually delete the host data directories unless the intention is to completely reset the project.

Removing the MariaDB volume/data can permanently remove:

* the WordPress database;
* WordPress users;
* WordPress settings;
* other stored database information.

---

## Persistent Data

The project uses Docker named volumes rather than bind mounts for the WordPress and MariaDB persistent storage.

The volumes store their data under:

```text
/home/tavd/data/
├── wordpress/
└── mariadb/
```

The corresponding container locations are:

```text
WordPress volume
    ↓
/var/www/

MariaDB volume
    ↓
/var/lib/mysql/
```

The important distinction is that the application containers can be recreated without losing the persistent data stored in these volumes.

### WordPress data

WordPress website files are stored persistently in the WordPress volume.

Inside the WordPress container, the volume is mounted at:

```text
/var/www/
```

### MariaDB data

The MariaDB database files are stored persistently in the MariaDB volume.

Inside the MariaDB container, the volume is mounted at:

```text
/var/lib/mysql/
```

### Check the host data

On the host VM:

```bash
ls -la /home/tavd/data/
```

Check WordPress data:

```bash
ls -la /home/tavd/data/wordpress/
```

Check MariaDB data:

```bash
ls -la /home/tavd/data/mariadb/
```

The exact contents are managed by Docker and the services.

---

## NGINX Configuration

NGINX is the only externally accessible service.

The infrastructure exposes HTTPS through:

```text
443
```

NGINX is configured to use TLS.

Only:

```text
TLSv1.2
TLSv1.3
```

are permitted.

NGINX receives browser requests and forwards PHP requests to the WordPress container using FastCGI:

```text
wordpress:9000
```

MariaDB is not exposed publicly.

WordPress/PHP-FPM is not exposed publicly.

The intended traffic flow is:

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

---

## WordPress Configuration

The WordPress container contains WordPress and PHP-FPM.

NGINX is not installed in the WordPress container.

The WordPress container communicates with MariaDB through the Docker network.

The database host is the MariaDB service name:

```text
mariadb
```

The database connection uses the internal MariaDB port:

```text
3306
```

PHP-FPM listens on:

```text
9000
```

WordPress files are stored in the persistent WordPress volume.

---

## MariaDB Configuration

MariaDB runs in its own dedicated container.

NGINX and WordPress are not installed in the MariaDB container.

The database data is stored in the persistent MariaDB volume.

MariaDB uses the credentials supplied through the configured Docker secrets and environment variables.

The database must contain the required WordPress users, including an administrator account whose username does not contain:

```text
admin
administrator
```

or equivalent capitalization/variations prohibited by the project requirements.

---

## Docker Secrets and Security

Passwords must not be placed directly in Dockerfiles.

The project uses Docker secrets for sensitive database passwords.

The secret files are:

```text
secrets/db_password.txt
secrets/db_root_password.txt
```

These files must remain local.

They must not be committed to Git.

Check the repository before committing:

```bash
git status
```

If necessary, verify that the secret files are ignored:

```bash
git check-ignore secrets/db_password.txt
git check-ignore secrets/db_root_password.txt
```

The project must never contain publicly stored:

* passwords;
* database credentials;
* API keys;
* other confidential credentials.

The `.env` file should also be handled according to the project's Git configuration and must not contain confidential values that should instead be stored as secrets.

---

## Rebuilding After Configuration Changes

When a Dockerfile or build configuration changes, rebuild the images:

```bash
make build
```

If a complete project recreation is required, use the Makefile's rebuild target:

```bash
make re
```

After rebuilding, verify that the containers are running:

```bash
docker ps
```

Check the logs if a service does not start:

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

---

## Troubleshooting

### Containers are not running

Check:

```bash
docker ps -a
```

Then inspect the logs:

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### NGINX is not accessible

Check that the NGINX container is running:

```bash
docker ps
```

Check the port:

```bash
docker port nginx
```

Check the NGINX logs:

```bash
docker logs nginx
```

Also verify that the domain name resolves to the correct local/VM address.

If the school host cannot use a normal `/etc/hosts` entry, use the Chrome workaround described in:

```text
School Environment and Browser Access
```

Start Chrome with:

```bash
google-chrome --user-data-dir=/tmp/chrome-test --host-resolver-rules="MAP tavdiiev.42.fr 127.0.0.1"
```

Then access:

```text
https://tavdiiev.42.fr:8443/
```

### WordPress cannot connect to MariaDB

Check that MariaDB is running:

```bash
docker ps
```

Check MariaDB logs:

```bash
docker logs mariadb
```

Check the Docker network:

```bash
docker network inspect inception
```

Verify that the WordPress configuration uses the MariaDB service name:

```text
mariadb
```

and the internal database port:

```text
3306
```

### WordPress/PHP-FPM is not responding

Check the WordPress container:

```bash
docker ps -a
```

Check its logs:

```bash
docker logs wordpress
```

Verify that PHP-FPM is running and listening on:

```text
9000
```

Also check the NGINX configuration and its FastCGI destination:

```text
wordpress:9000
```

### WordPress installation page does not appear

If expecting the initial WordPress installation page, first check whether the persistent WordPress and MariaDB volumes already contain data.

Check the Docker volumes:

```bash
docker volume ls
```

Check the host data directory:

```bash
ls -la /home/tavd/data/
```

If WordPress has already been initialized, the existing installation will normally be used instead of displaying the installation form.

Do not delete the volumes unless intentionally resetting the project.

If testing a clean installation, the expected workflow is:

```text
Empty persistent data
        │
        ▼
Start containers
        │
        ▼
Open /wp-admin/
        │
        ▼
WordPress installation page
        │
        ▼
Create administrator
        │
        ▼
Log in to dashboard
        │
        ▼
Create normal user
```

The exact first-start behavior should be verified in a clean clone/environment before treating it as fully confirmed.

### Data appears to be missing

First check the Docker volumes:

```bash
docker volume ls
```

Then inspect the relevant volume:

```bash
docker volume inspect <volume_name>
```

Check the host data directory:

```bash
ls -la /home/tavd/data/
```

Do not remove the volumes while troubleshooting unless you intentionally want to reset the project.

---

## Cleaning the Project

The normal way to stop and remove the running containers is:

```bash
make down
```

This does not normally remove the persistent WordPress and MariaDB data.

Be careful with Docker commands that include volume removal.

For example:

```bash
docker compose down -v
```

removes the Compose volumes.

This should only be used when intentionally resetting the persistent project data.

Before performing a destructive cleanup, make sure that losing the WordPress database and website data is acceptable.

---

## Development Workflow

A typical development workflow is:

### 1. Enter the project directory

```bash
cd ~/inception
```

### 2. Check the project files

```bash
ls -la
```

### 3. Check Docker

```bash
docker info
```

### 4. Build and start the project

```bash
make build
```

### 5. Check the containers

```bash
docker ps
```

### 6. Check logs if necessary

```bash
docker logs nginx
docker logs wordpress
docker logs mariadb
```

### 7. Access the website

In the school environment, start Chrome with:

```bash
google-chrome --user-data-dir=/tmp/chrome-test --host-resolver-rules="MAP tavdiiev.42.fr 127.0.0.1"
```

Then open:

```text
https://tavdiiev.42.fr:8443/
```

The WordPress administrator area is:

```text
https://tavdiiev.42.fr:8443/wp-admin/
```

### 8. Make configuration or Dockerfile changes

Edit the relevant files under:

```text
srcs/
```

and:

```text
srcs/requirements/
```

### 9. Rebuild after Dockerfile changes

```bash
make build
```

or:

```bash
make re
```

### 10. Stop the project when finished

```bash
make down
```

Persistent data remains in the Docker named volumes unless those volumes are explicitly removed.

---

## Important Project Constraints

When modifying the project, keep the Inception requirements in mind.

### Containers

Each service must run in its own dedicated container:

```text
nginx
wordpress
mariadb
```

### Images

The project images must be built using the project's own Dockerfiles.

Do not replace the project services with ready-made application images.

Do not use the `latest` tag.

### Network

The services must communicate through the project's Docker network.

Do not use:

```text
network: host
```

or Docker links.

### Entry point

NGINX must be the only external entry point.

The infrastructure must be accessible externally through:

```text
443
```

using TLSv1.2 or TLSv1.3.

### Persistent storage

WordPress and MariaDB must use Docker named volumes.

Do not replace the required persistent volumes with bind mounts.

The persistent data must be stored under:

```text
/home/tavd/data/
```

### Security

Never place passwords directly in Dockerfiles.

Never commit passwords, credentials, API keys, or other confidential information to Git.

Use environment variables for configuration and Docker secrets for confidential information.

### Container processes

Do not use infinite-loop hacks such as:

```text
tail -f
bash
sleep infinity
while true
```

to keep containers alive.

Each container should run its actual service as its main process.

---

## Quick Reference

| **Action** | **Command** |
| --- | --- |
| Start | `make` |
| Build and start | `make build` |
| Stop | `make down` |
| Rebuild | `make re` |
| Check running containers | `docker ps` |
| Check all containers | `docker ps -a` |
| List images | `docker image ls` |
| List volumes | `docker volume ls` |
| List networks | `docker network ls` |
| Inspect network | `docker network inspect inception` |
| NGINX logs | `docker logs nginx` |
| WordPress logs | `docker logs wordpress` |
| MariaDB logs | `docker logs mariadb` |
| Inspect NGINX | `docker inspect nginx` |
| Inspect WordPress | `docker inspect wordpress` |
| Inspect MariaDB | `docker inspect mariadb` |
| Project data | `/home/tavd/data/` |
| WordPress data | `/home/tavd/data/wordpress/` |
| MariaDB data | `/home/tavd/data/mariadb/` |
| WordPress mount | `/var/www/` |
| MariaDB mount | `/var/lib/mysql/` |
| NGINX HTTPS | `443` |
| School VirtualBox HTTPS | `8443` → VM `443` |
| WordPress/PHP-FPM | `wordpress:9000` |
| MariaDB | `mariadb:3306` |
