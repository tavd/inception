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
```

Only NGINX is exposed to the outside. WordPress/PHP-FPM and MariaDB are used internally by the stack.

## Starting the Project

From the root of the repository, run:

```bash
make
```

This starts the Docker Compose infrastructure in detached mode.

If the Docker images need to be rebuilt, use:

```bash
make build
```

After starting the project, check that the containers are running:

```bash
docker ps
```

You should see containers for:

- `nginx`
- `wordpress`
- `mariadb`

## Stopping the Project

To stop the project:

```bash
make down
```

This stops and removes the Docker Compose containers and network.

The persistent WordPress and MariaDB data is normally kept when using `make down`.

## Accessing the Website

The website is served through NGINX using HTTPS.

For the configured domain, open:

[https://tavdiiev.42.fr/](https://tavdiiev.42.fr/)

In a local virtual-machine setup where port forwarding is used, the HTTPS port may be accessed through the forwarded host port, for example:

[https://tavdiiev.42.fr:8443/](https://tavdiiev.42.fr:8443/)

The exact URL depends on the VirtualBox port-forwarding configuration used to access the VM.

NGINX handles the HTTPS connection and forwards PHP requests to the WordPress container.

## Accessing the Administration Panel

The WordPress administration panel is available at:

[https://tavdiiev.42.fr/wp-admin/](https://tavdiiev.42.fr/wp-admin/)

or, when using the local VirtualBox HTTPS forwarding port:

[https://tavdiiev.42.fr:8443/wp-admin/](https://tavdiiev.42.fr:8443/wp-admin/)

Log in using the WordPress administrator account created during WordPress installation.

The WordPress administrator account is separate from the MariaDB database account.

## Credentials

There are two different types of credentials used by the infrastructure.

### Database credentials

Database passwords are stored as Docker secrets rather than being placed directly in the Docker Compose file or Dockerfiles.

The secret files are:

- `secrets/db_password.txt`
- `secrets/db_root_password.txt`

They are used by the MariaDB and WordPress containers through Docker's secret mechanism.

These files contain sensitive information and must not be committed to the Git repository.

### WordPress credentials

WordPress administrator and user credentials are managed by WordPress itself.

The WordPress administrator uses the username and password created during the WordPress installation process to access:

```text
/wp-admin/
```

These credentials are stored by WordPress in the MariaDB database.

The WordPress administrator password is not the same thing as the MariaDB root password or the WordPress database user's password.

## Checking That the Services Are Running

Use:

```bash
docker ps
```

to see the running containers.

You should see the three project services:

- `nginx`
- `wordpress`
- `mariadb`

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

The logs can help identify startup errors or configuration problems.

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

The data is stored under:

```text
/home/<user>/data/
├── wordpress/
└── mariadb/
```

The exact `<user>` is the Linux user running the project.

The WordPress data is mounted into the containers at:

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

| **Action** | **Command** |
| --- | --- |
| Start | `make` |
| Build and start | `make build` |
| Stop | `make down` |
| Rebuild | `make re` |
| Check running containers | `docker ps` |
| Check all containers | `docker ps -a` |
| NGINX logs | `docker logs nginx` |
| WordPress logs | `docker logs wordpress` |
| MariaDB logs | `docker logs mariadb` |
| Website | [https://tavdiiev.42.fr/](https://tavdiiev.42.fr/) |
| WordPress admin | [https://tavdiiev.42.fr/wp-admin/](https://tavdiiev.42.fr/wp-admin/) |
