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

For a test from the school host, use:

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
WP_ADMIN_USER=example_user
WP_ADMIN_EMAIL=example_user@example.com
WP_USER=example_user2
WP_USER_EMAIL=example_user2@example.com
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
