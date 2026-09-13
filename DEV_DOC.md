**# Inception — Developer Documentation**

**## Overview**

This project implements a small Docker-based infrastructure running WordPress with PHP-FPM, MariaDB, and NGINX.

The infrastructure consists of three services:

* ****NGINX**** — the only public entry point. It handles HTTPS connections and forwards PHP requests to WordPress/PHP-FPM.

* ****WordPress with PHP-FPM**** — runs the WordPress application and processes PHP requests.

* ****MariaDB**** — stores the WordPress database.

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

**## Prerequisites**

Before setting up the project, make sure the following are available inside the virtual machine:

* A supported Linux distribution, such as Debian.

* Docker.

* Docker Compose.

* Git.

* `make`.

* A shell such as `bash`.

* Sufficient disk space for Docker images and persistent WordPress/MariaDB data.

The project must be run inside a virtual machine as required by the Inception subject.

**### Docker requirements**

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

**## Project Structure**

The project has the following general structure:

```text

inception/

├── Makefile

├── secrets/

│   ├── db_password.txt

│   ├── db_root_password.txt

│   ├── wp_admin_password.txt

│   └── wp_user_password.txt

└── srcs/

```
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

```

The exact contents of the `conf/` and `tools/` directories depend on the implementation of each service.

**### Makefile**

The `Makefile` provides the main commands used to build, start, stop, and rebuild the infrastructure.

**### `srcs/docker-compose.yml`**

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

**### `srcs/.env`**

The `.env` file contains non-secret environment variables used by Docker Compose and the service configuration.

For example:

```text

DOMAIN_NAME=tavdiiev.42.fr
```

Other project-specific variables such as the MariaDB database name, database username, WordPress title, WordPress usernames, email addresses, and WordPress URL are also configured through environment variables.

The WordPress URL should remain:

```text

WP_URL=https://tavdiiev.42.fr
```

The VirtualBox forwarding port `8443` must not be added to `WP_URL`. The project itself uses HTTPS on NGINX port `443`; `8443` is only used as a host-side forwarding port in the school environment.

Passwords and other confidential information must not be placed directly in this file when they are handled through Docker secrets.

**### `secrets/`**

The `secrets/` directory contains confidential information required by MariaDB and WordPress.

The project uses:

```text

secrets/db_password.txt
secrets/db_root_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
```

Their purposes are:

* `db_password.txt` — password for the WordPress MariaDB user.

* `db_root_password.txt` — MariaDB root password.

* `wp_admin_password.txt` — password for the automatically created WordPress administrator.

* `wp_user_password.txt` — password for the automatically created normal WordPress user.

These files must remain local and must not be committed to Git.

---

**## Setting Up the Environment From Scratch**

**### 1. Start the virtual machine**

Start the Linux virtual machine used for the Inception project.

Open a terminal and make sure you are working inside the project directory.

For example:

```bash

cd ~/inception
```

**### 2. Clone or copy the project**

If the project is stored in a Git repository, clone it into the virtual machine:

```bash

git clone <repository>

cd inception
```

Do not commit passwords, credentials, API keys, or other confidential information to the repository.

Because `.env`, secrets, certificates, and private keys are ignored by Git, these files must be created or supplied locally after cloning.

**### 3. Check the directory structure**

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

The `.env` file is intentionally not committed to the repository, so it must be created locally if it is not already present.

**### 4. Create the secrets**

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

Create the WordPress administrator password secret:

```bash

nano secrets/wp_admin_password.txt
```

Enter the password that should be used for the automatically created WordPress administrator.

Create the normal WordPress user password secret:

```bash

nano secrets/wp_user_password.txt
```

Enter the password that should be used for the automatically created normal WordPress user.

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

**### 5. Configure the `.env` file**

Edit:

```bash

nano srcs/.env
```

The `.env` file contains the environment variables required by the Docker Compose configuration.

For this project, the configuration includes values such as:

```text

DOMAIN_NAME=tavdiiev.42.fr
DB_NAME=wordpress
DB_USER=wpuser
WP_TITLE=Inception
WP_ADMIN_USER=tavd_user1
WP_ADMIN_EMAIL=[some_email@gmail.com](mailto:some_email@gmail.com)
WP_USER=tavd_user2
WP_USER_EMAIL=[some_email2@gmail.com](mailto:some_email2@gmail.com)
WP_URL=https://tavdiiev.42.fr
```

The actual email addresses and other project-specific values can be changed as required.

Passwords should be provided through Docker secrets rather than hard-coded into Dockerfiles or Compose configuration.

The WordPress administrator username must not contain `admin` or `administrator`, including prohibited capitalization or equivalent variations.

**### 6. Configure the domain name**

The project domain must follow the required format:

```text

<login>.42.fr
```

For this project:

```text

tavdiiev.42.fr
```

The domain must resolve to the IP address through which the NGINX container can be reached.

Inside the virtual machine, a hosts entry can be used so that:

```text

tavdiiev.42.fr
```

resolves to the local machine.

In the school environment, the host computer may have restrictions preventing modification of its system `/etc/hosts` file. See the **School Environment and Browser Access** section for the corresponding workaround.

**### 7. Check the Docker configuration**

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

**## School Environment and Browser Access**

The Inception project runs inside a Debian virtual machine.

In the school environment, the host computer may not allow modification of the system `/etc/hosts` file. In that situation, the domain:

```text

tavdiiev.42.fr
```

cannot necessarily be resolved normally by the browser.

A separate Chrome profile can be started with a temporary host-resolution rule that maps the project domain to the local machine.

**### Start Chrome with the project domain mapped locally**

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

**### Important distinction between ports 443 and 8443**

The project itself uses NGINX on port:

```text

443
```

The school VirtualBox configuration forwards the host computer's:

```text

127.0.0.1:8443
```

to the virtual machine's:

```text

443
```

Therefore:

```text

8443
```

is only a host-side VirtualBox forwarding port.

It is **not** the HTTPS port used by NGINX inside the Inception infrastructure.

The project URL remains:

```text

https://tavdiiev.42.fr
```

and the `.env` file should contain:

```text

WP_URL=https://tavdiiev.42.fr
```

not:

```text

WP_URL=https://tavdiiev.42.fr:8443
```

The connection path is:

```text

School PC

```
│

│ 127.0.0.1:8443

▼
```

VirtualBox port forwarding

```
│

│ VM :443

▼
```

NGINX :443

```
│

│ FastCGI :9000

▼
```

WordPress / PHP-FPM

```
│

│ MySQL :3306

▼
```

MariaDB
```

**### Testing from the school host**

Because WordPress uses the canonical URL:

```text

https://tavdiiev.42.fr
```

a browser request through:

```text

https://tavdiiev.42.fr:8443/
```

can be redirected by WordPress to the canonical HTTPS URL without `:8443`.

For a clean test that does not require changing the WordPress canonical URL, use `curl` from the school host:

```bash

curl -kI -H "Host: tavdiiev.42.fr" https://127.0.0.1:8443/
```

A successful response should look similar to:

```text

HTTP/1.1 200 OK
Server: nginx
Content-Type: text/html; charset=UTF-8
```

This verifies the path:

```text

school host
↓
127.0.0.1:8443
↓
VirtualBox
↓
VM :443
↓
NGINX
↓
WordPress
```

while keeping the project's canonical URL correct.

**### Browser testing through port 8443**

If a browser test through `8443` is specifically required, WordPress's `home` and `siteurl` options can temporarily be changed to include `:8443`.

For example:

```bash

docker exec wordpress wp option update home 'https://tavdiiev.42.fr:8443' --allow-root

docker exec wordpress wp option update siteurl 'https://tavdiiev.42.fr:8443' --allow-root
```

The browser can then be opened at:

```text

https://tavdiiev.42.fr:8443/
```

or:

```text

https://tavdiiev.42.fr:8443/wp-admin/
```

After browser testing, restore the project's actual canonical URL:

```bash

docker exec wordpress wp option update home 'https://tavdiiev.42.fr' --allow-root

docker exec wordpress wp option update siteurl 'https://tavdiiev.42.fr' --allow-root
```

Verify:

```bash

docker exec wordpress wp option get home --allow-root

docker exec wordpress wp option get siteurl --allow-root
```

The final project configuration should use:

```text

https://tavdiiev.42.fr
```

without `:8443`.

---

**## Automatic WordPress Installation**

WordPress installation is automated by the WordPress container using WP-CLI.

The project does not require manually opening the WordPress installation page and entering the administrator and normal-user information through the browser.

The required WordPress credentials are supplied through Docker secrets and the non-secret configuration is supplied through `.env`.

**### 1. Start the infrastructure**

From the project root:

```bash

make
```

The Makefile builds/starts the Docker Compose infrastructure.

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

**### 2. WordPress startup process**

When the WordPress container starts, its startup script performs the following steps:

```text

Start WordPress container
│
▼
Create wp-config.php if necessary
│
▼
Wait for MariaDB to become available
│
▼
Check whether WordPress is installed
│
├── Already installed
│       │
│       ▼
│   Skip installation
│
└── Not installed
│
▼
Run wp core install
│
▼
Create normal WordPress user
│
▼
Start PHP-FPM
```

The startup script first runs the WordPress configuration script.

If `/var/www/wp-config.php` does not exist, it is generated using the database configuration and the database password stored in the Docker secret.

The WordPress container then waits until MariaDB accepts a connection.

**### 3. Automatic WordPress installation**

On a clean WordPress data directory, WP-CLI checks:

```bash

wp core is-installed --allow-root
```

If WordPress is not installed, the startup script runs:

```text

wp core install
```

using:

* `WP_URL` from `.env`;

* `WP_TITLE` from `.env`;

* `WP_ADMIN_USER` from `.env`;

* `WP_ADMIN_EMAIL` from `.env`;

* the administrator password from `secrets/wp_admin_password.txt`.

The installation uses `--skip-email` because email configuration is not required for the local Inception installation.

After installing WordPress, the startup script creates the normal user using:

* `WP_USER` from `.env`;

* `WP_USER_EMAIL` from `.env`;

* the password from `secrets/wp_user_password.txt`;

* the `subscriber` role.

**### 4. Verify the installation**

Check whether WordPress is installed:

```bash

docker exec wordpress wp core is-installed --allow-root
```

A successful command exits without an error.

Check the WordPress version:

```bash

docker exec wordpress wp core version --allow-root
```

List the WordPress users:

```bash

docker exec wordpress wp user list --allow-root
```

The expected users are:

```text

tavd_user1
tavd_user2
```

with the administrator and subscriber roles respectively.

**### 5. Check the WordPress startup logs**

The WordPress logs can be viewed with:

```bash

docker logs wordpress
```

On a clean installation, the logs should contain messages similar to:

```text

Waiting for MariaDB...
WordPress is not installed. Installing...
Success: WordPress installed successfully.
Success: Created user 2.
```

On a subsequent container start where the persistent WordPress installation already exists, the installation should be skipped and the logs should contain:

```text

WordPress is already installed.
```

**### Important note about persistent data**

The WordPress installation state is stored in the persistent WordPress and MariaDB data.

If WordPress has already been initialized, restarting or recreating the containers will normally keep the existing installation.

For example:

```bash

make down
```

does not normally remove the persistent volumes.

Therefore, a completely fresh automatic installation test requires intentionally resetting the persistent WordPress and MariaDB data.

Do not remove the persistent data merely to test the installation unless losing the existing database and website data is acceptable.

---

**## Building the Project**

The project images are built from the project's own Dockerfiles.

Ready-made application images must not be pulled for the project services.

The base images are based on the required Alpine version used by the project implementation.

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

**### Check the built images**

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

**## Launching the Project**

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

**## Checking the Docker Network**

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

**## Managing Containers**

**### Check running containers**

```bash

docker ps
```

**### Check all containers**

To include stopped containers:

```bash

docker ps -a
```

**### View container logs**

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

**### Inspect a container**

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

**### Open a shell inside a container**

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

**## Managing the Project With the Makefile**

The Makefile is the preferred way to manage the project.

**### Start the project**

```bash

make
```

**### Build the project**

```bash

make build
```

This rebuilds the Docker images and starts the infrastructure according to the Makefile.

**### Stop the project**

```bash

make down
```

This stops and removes the Docker Compose containers and network.

The persistent named volumes are normally kept.

**### Rebuild the project**

```bash

make re
```

This target is used to rebuild/recreate the project according to the Makefile configuration.

The exact sequence is defined by the project's Makefile.

---

**## Managing Docker Compose Directly**

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

**## Managing Volumes**

The project defines two Docker named volumes for persistent storage:

* `wp-volume` for WordPress files.

* `db-volume` for MariaDB database files.

These are **named Docker volumes** whose storage is backed by the required host directories under:

```text

/home/${USER}/data/
```

through the volume driver's bind configuration.

List Docker volumes:

```bash

docker volume ls
```

Inspect a volume:

```bash

docker volume inspect <volume_name>
```

The volumes are mounted inside the containers at:

```text

/var/www/
```

for WordPress files, and:

```text

/var/lib/mysql/
```

for MariaDB data.

**### Important: Do Not Remove the Volumes Accidentally**

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

**## Persistent Data**

The project defines named Docker volumes:

```text

wp-volume

db-volume
```

Their storage is backed by the following host directories:

```text

/home/tavd/data/

├── wordpress/

└── mariadb/
```

The corresponding container locations are:

```text

WordPress volume

```
↓
```

/var/www/

MariaDB volume

```
↓
```

/var/lib/mysql/
```

This allows the application containers to be recreated without losing the persistent data stored in the volumes.

**### WordPress data**

WordPress website files are stored persistently in the WordPress volume.

Inside the WordPress container, the volume is mounted at:

```text

/var/www/
```

**### MariaDB data**

The MariaDB database files are stored persistently in the MariaDB volume.

Inside the MariaDB container, the volume is mounted at:

```text

/var/lib/mysql/
```

**### Check the host data**

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

**## NGINX Configuration**

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

**## WordPress Configuration**

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

**### WordPress configuration and WP-CLI**

The WordPress container uses:

```text

/usr/local/bin/wp-config-create.sh
```

to create `wp-config.php` when it does not already exist.

The database password is read from:

```text

/run/secrets/db_password
```

The WordPress startup script:

```text

/usr/local/bin/wp.sh
```

then waits for MariaDB and checks whether WordPress has already been installed.

WP-CLI is used to perform the initial installation automatically when necessary.

---

**## MariaDB Configuration**

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

**## Docker Secrets and Security**

Passwords must not be placed directly in Dockerfiles.

The project uses Docker secrets for sensitive MariaDB and WordPress passwords.

The secret files are:

```text

secrets/db_password.txt
secrets/db_root_password.txt
secrets/wp_admin_password.txt
secrets/wp_user_password.txt
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

git check-ignore secrets/wp_admin_password.txt

git check-ignore secrets/wp_user_password.txt
```

The project must never contain publicly stored:

* passwords;

* database credentials;

* API keys;

* other confidential credentials.

The `.env` file should also be handled according to the project's Git configuration and must not contain confidential values that should instead be stored as secrets.

---

**## Rebuilding After Configuration Changes**

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

**## Troubleshooting**

**### Containers are not running**

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

**### NGINX is not accessible**

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

From inside the VM, test the HTTPS endpoint directly:

```bash

curl -kI https://tavdiiev.42.fr/
```

A successful response should return an HTTP status such as:

```text

HTTP/1.1 200 OK
```

If testing from the school host, use:

```bash

curl -kI -H "Host: tavdiiev.42.fr" https://127.0.0.1:8443/
```

This uses the school VirtualBox forwarding port while explicitly supplying the required hostname.

If the school host cannot use a normal `/etc/hosts` entry, use the Chrome workaround described in **School Environment and Browser Access**.

**### WordPress cannot connect to MariaDB**

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

The WordPress container also waits for MariaDB during startup. Check:

```bash

docker logs wordpress
```

for messages such as:

```text

Waiting for MariaDB...
```

**### WordPress/PHP-FPM is not responding**

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

**### Automatic WordPress installation does not complete**

First check the WordPress logs:

```bash

docker logs wordpress
```

On a clean installation, the logs should show the startup sequence, including messages similar to:

```text

Waiting for MariaDB...
WordPress is not installed. Installing...
Success: WordPress installed successfully.
Success: Created user 2.
```

Check whether WordPress considers itself installed:

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

If WordPress is already installed, the startup script intentionally skips the installation.

The logs should then contain:

```text

WordPress is already installed.
```

**### Testing automatic installation from a clean state**

The automatic installation is intended to run when the persistent WordPress data is empty.

Before performing a destructive reset, check the existing data:

```bash

ls -la /home/tavd/data/
```

The WordPress data is stored under:

```text

/home/tavd/data/wordpress/
```

and MariaDB data under:

```text

/home/tavd/data/mariadb/
```

A clean automatic installation test follows this general sequence:

```text

Empty persistent WordPress/MariaDB data

```
    │

    ▼
```

Start containers

```
    │

    ▼
```

WordPress creates wp-config.php

```
    │

    ▼
```

Wait for MariaDB

```
    │

    ▼
```

Check wp core is-installed

```
    │

    ▼
```

Run wp core install

```
    │

    ▼
```

Create normal user

```
    │

    ▼
```

Start PHP-FPM
```

Do not delete persistent data unless intentionally resetting the project.

**### WordPress already appears to be installed**

This is expected when the persistent data already contains a WordPress installation.

Check:

```bash

docker exec wordpress wp core is-installed --allow-root
```

If the command succeeds, WordPress is already initialized.

The startup script will not reinstall WordPress or recreate the normal user.

This prevents existing persistent data from being overwritten during normal container restarts or recreation.

**### Data appears to be missing**

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

**## Cleaning the Project**

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

**## Development Workflow**

A typical development workflow is:

**### 1. Enter the project directory**

```bash

cd ~/inception
```

**### 2. Check the project files**

```bash

ls -la
```

**### 3. Check Docker**

```bash

docker info
```

**### 4. Build and start the project**

```bash

make build
```

**### 5. Check the containers**

```bash

docker ps
```

**### 6. Check logs if necessary**

```bash

docker logs nginx

docker logs wordpress

docker logs mariadb
```

**### 7. Verify the automatic WordPress installation**

Check:

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

**### 8. Test HTTPS from the VM**

```bash

curl -kI https://tavdiiev.42.fr/
```

**### 9. Test HTTPS from the school host**

Because the school host uses VirtualBox forwarding from `8443` to the VM's `443`, use:

```bash

curl -kI -H "Host: tavdiiev.42.fr" https://127.0.0.1:8443/
```

This tests the project without changing the canonical WordPress URL.

**### 10. Make configuration or Dockerfile changes**

Edit the relevant files under:

```text

srcs/
```

and:

```text

srcs/requirements/
```

**### 11. Rebuild after Dockerfile changes**

```bash

make build
```

or:

```bash

make re
```

**### 12. Stop the project when finished**

```bash

make down
```

Persistent data remains in the Docker named volumes unless those volumes are explicitly removed.

---

**## Important Project Constraints**

When modifying the project, keep the Inception requirements in mind.

**### Containers**

Each service must run in its own dedicated container:

```text

nginx

wordpress

mariadb
```

**### Images**

The project images must be built using the project's own Dockerfiles.

Do not replace the project services with ready-made application images.

Do not use the `latest` tag.

**### Network**

The services must communicate through the project's Docker network.

Do not use:

```text

network: host
```

or Docker links.

**### Entry point**

NGINX must be the only external entry point.

The infrastructure must be accessible externally through:

```text

443
```

using TLSv1.2 or TLSv1.3.

The school environment may use host-side VirtualBox port `8443` to forward to the VM's port `443`. This does not change the project's actual NGINX port.

**### Persistent storage**

The project defines Docker named volumes:

```text

wp-volume

db-volume
```

Their storage is backed by the required host directories under:

```text

/home/${USER}/data/
```

through the Docker volume driver's bind configuration.

The persistent data must therefore remain under the required host data directories.

**### Security**

Never place passwords directly in Dockerfiles.

Never commit passwords, credentials, API keys, or other confidential information to Git.

Use environment variables for non-secret configuration and Docker secrets for confidential information.

**### Container processes**

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

**## Quick Reference**

| ****Action**** | ****Command**** |

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

| Check WordPress installation | `docker exec wordpress wp core is-installed --allow-root` |

| Check WordPress version | `docker exec wordpress wp core version --allow-root` |

| List WordPress users | `docker exec wordpress wp user list --allow-root` |

| Test HTTPS from VM | `curl -kI https://tavdiiev.42.fr/\` |

| Test HTTPS from school host | `curl -kI -H "Host: tavdiiev.42.fr" https://127.0.0.1:8443/\` |

| Project data | `/home/tavd/data/` |

| WordPress data | `/home/tavd/data/wordpress/` |

| MariaDB data | `/home/tavd/data/mariadb/` |

| WordPress mount | `/var/www/` |

| MariaDB mount | `/var/lib/mysql/` |

| NGINX HTTPS | `443` |

| School VirtualBox HTTPS | `8443` → VM `443` |

| WordPress/PHP-FPM | `wordpress:9000` |

| MariaDB | `mariadb:3306` |
