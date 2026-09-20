# Inception — User Documentation

## Overview

This project provides a WordPress website running as a Docker-based infrastructure.
The stack consists of three services:
* **NGINX** — receives HTTPS requests from the browser and serves as the public entry point.
* **WordPress with PHP-FPM** — runs the WordPress application and processes PHP code.
* **MariaDB** — stores the WordPress database.

The services communicate through a private Docker network.

```
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

## Configuration

Before starting the project from a fresh clone, create the local configuration and Docker secret files from the provided example files.
The main configuration template is:

```
srcs/.env.example
```
Copy it to create the local `.env` file:

```bash
cp srcs/.env.example srcs/.env
```
The `.env` file contains non-sensitive project configuration such as:
* domain name;
* database name and user;
* WordPress site title;
* WordPress administrator username and email;
* WordPress normal user username and email;
* canonical WordPress URL.
The project uses Docker secrets for passwords. The provided secret templates are:
```
secrets/
├── db_password.txt.example
├── db_root_password.txt.example
├── wp_admin_password.txt.example
└── wp_user_password.txt.example
```
Create the local secret files:
```bash
cp secrets/db_password.txt.example secrets/db_password.txt
cp secrets/db_root_password.txt.example secrets/db_root_password.txt
cp secrets/wp_admin_password.txt.example secrets/wp_admin_password.txt
cp secrets/wp_user_password.txt.example secrets/wp_user_password.txt
```
The resulting local files are:

```
srcs/.env
secrets/
├── db_password.txt
├── db_root_password.txt
├── wp_admin_password.txt
└── wp_user_password.txt
```

The local `.env` file and secret files are excluded from Git.
The project also requires a local TLS certificate and private key for NGINX. These files are environment-specific and are excluded from Git. See `DEV_DOC.md` for the certificate creation procedure.

## Starting the Project

After completing the local configuration, from the root of the repository run:

```bash
make
```

This creates the required persistent-data directories if necessary and starts the Docker Compose infrastructure in detached mode.

When the WordPress container starts for the first time, the project automatically:
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

## Testing Inside the VM

The project can first be tested directly from inside the Debian VM, without using the VirtualBox host-side forwarding port.

After starting the project, verify that the containers are running:

```bash
docker ps
```

The expected containers are:

```text
nginx
wordpress
mariadb
```

The VM resolves the domain locally through `/etc/hosts`:

```text
127.0.0.1    localhost tavdiiev.42.fr
```

Then test the HTTPS entry point directly on the VM:

```bash
curl -kI https://tavdiiev.42.fr/
```

A successful response should indicate that the request reaches NGINX on port 443 and is handled by the WordPress application.

## Testing from the School Host

In the school virtual-machine environment, VirtualBox forwards:

```
Host 127.0.0.1:8443
     │
     ▼
 VM port 443
     │
     ▼
   NGINX

```

Therefore, `8443` is only the local VirtualBox forwarding port. It is not part of the project's actual NGINX or WordPress configuration.

The project itself uses HTTPS port `443`, and the canonical WordPress URL remains:

```
https://tavdiiev.42.fr
```

For a command-line test from the school host, use:

```bash
curl -kI -H "Host: tavdiiev.42.fr" https://127.0.0.1:8443/
```

This sends the request to the school host's forwarded port and supplies the expected hostname through the `Host` header.

## Browser Testing from the School Host

The browser URL used through the school host's VirtualBox forwarding is:

```text

https://tavdiiev.42.fr:8443/

```

If the school host cannot resolve `tavdiiev.42.fr` normally, Chrome can be started with a temporary host-resolution rule:

```bash

google-chrome \
    --user-data-dir=/tmp/chrome-test \
    --host-resolver-rules="MAP tavdiiev.42.fr 127.0.0.1"

```

The `--host-resolver-rules` option makes Chrome resolve `tavdiiev.42.fr` to the school host's `127.0.0.1`, allowing the request to reach the VirtualBox forwarding port.
The separate `--user-data-dir` creates a temporary Chrome profile for this test.
The browser then accesses:

```text

https://tavdiiev.42.fr:8443/

```

Because WordPress normally uses the canonical URL:

```text

https://tavdiiev.42.fr

```

WordPress may redirect the browser from the forwarded `:8443` URL to the canonical URL without `:8443`.
For browser testing through `:8443`, temporarily change **both** the WordPress `home` and `siteurl` options to:

```text

https://tavdiiev.42.fr:8443

```

This is required for full browser testing from the school host, including the public site, `/wp-admin/`, and the WordPress login page.

The `home` option controls the public site URL, while `siteurl` is also used for WordPress administration and login URLs. Therefore, changing only `home` is sufficient for testing the public homepage, but not for the complete WordPress admin/login flow.

After testing, restore **both** options to:

```text

https://tavdiiev.42.fr

```

Do not add `:8443` to `WP_URL` in the project's final configuration. `:8443` is only the school host's VirtualBox forwarding port; the project itself uses HTTPS on port 443.

## Accessing the Website

The public website is served through NGINX using HTTPS.

The configured project URL is:

```
https://tavdiiev.42.fr/
```

NGINX listens on HTTPS port `443`.

Only NGINX is exposed to the outside. WordPress/PHP-FPM and MariaDB communicate internally through the Docker network.

## Accessing the Administration Panel

The WordPress administration panel is available at:

```
https://tavdiiev.42.fr/wp-admin/
```

The administrator account is created automatically when WordPress is installed for the first time.
Log in using the WordPress administrator username and password configured for the project.
The WordPress administrator account is separate from the MariaDB database account.
When testing through the school host's VirtualBox `:8443` forwarding port, browser access may redirect to the canonical URL without `:8443`. See **Browser Testing from the School Host** above.

## Credentials

There are two different groups of credentials used by the infrastructure: database credentials and WordPress credentials.

### Database Credentials

Database passwords are stored as Docker secrets rather than being placed directly in the Docker Compose file or Dockerfiles.

The database secret files are:

* `secrets/db_password.txt`
* `secrets/db_root_password.txt`

Their purposes are:

* `db_password.txt` — password of the MariaDB user used by WordPress.
* `db_root_password.txt` — password of the MariaDB root user.

These files contain sensitive information and must not be committed to the Git repository.

### WordPress Credentials

WordPress passwords are also supplied through Docker secrets.

The WordPress password secret files are:

* `secrets/wp_admin_password.txt`
* `secrets/wp_user_password.txt`

Their purposes are:

* `wp_admin_password.txt` — password for the WordPress administrator account.
* `wp_user_password.txt` — password for the normal/subscriber WordPress user.

The usernames and other WordPress settings are configured through the project's `srcs/.env` file.

For example:

```
WP_ADMIN_USER=example_user
WP_ADMIN_EMAIL=[example_user@example.com](mailto:example_user@example.com)
WP_USER=example_user2
WP_USER_EMAIL=[example_user2@example.com](mailto:example_user2@example.com)
```

During the first startup, WP-CLI uses these values and the Docker secrets to install WordPress and create the two WordPress accounts automatically.
The WordPress administrator password is not the same thing as the MariaDB root password or the WordPress database user's password.
All secret files and the local `.env` file are excluded from the Git repository.

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

### Checking the Logs

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

The WordPress logs can also show whether the automatic installation was performed or skipped.
On a fresh WordPress data directory, the logs should contain messages indicating that WordPress was installed and the users were created.
When WordPress is already installed, the installation is skipped.

### Checking the Services Individually

You can inspect the NGINX container with:

```bash
docker inspect nginx
```

You can inspect the WordPress container with:

```bash
docker inspect wordpress
```

You can inspect the MariaDB container with:

```bash
docker inspect mariadb
```

These commands show information such as the container state, network configuration, mounts, and other Docker configuration.

## Checking Persistent Data

The project uses persistent storage for WordPress and MariaDB.
The required host storage directories are:

```
/home/<user>/data/
├── wordpress/
└── mariadb/
```

The exact `<user>` is the Linux user running the project.
The project defines named Docker volumes for WordPress and MariaDB. Their storage is backed by the required host directories above.
The WordPress data is mounted into the container at:

```
/var/www/
```

MariaDB data is mounted at:

```
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

| **Action**                   | **Command**                                                                                           |
| ---------------------------- | ----------------------------------------------------------------------------------------------------- |
| Start                        | `make`                                                                                                |
| Build and start              | `make build`                                                                                          |
| Stop                         | `make down`                                                                                           |
| Rebuild                      | `make re`                                                                                             |
| Check running containers     | `docker ps`                                                                                           |
| Check all containers         | `docker ps -a`                                                                                        |
| Check WordPress installation | `docker exec wordpress wp core is-installed --allow-root`                                             |
| Check WordPress version      | `docker exec wordpress wp core version --allow-root`                                                  |
| List WordPress users         | `docker exec wordpress wp user list --allow-root`                                                     |
| NGINX logs                   | `docker logs nginx`                                                                                   |
| WordPress logs               | `docker logs wordpress`                                                                               |
| MariaDB logs                 | `docker logs mariadb`                                                                                 |
| VM HTTPS test                | `curl -kI https://tavdiiev.42.fr/`                                                                    |
| School host HTTPS test       | `curl -kI -H "Host: tavdiiev.42.fr" https://127.0.0.1:8443/`                                          |
| Website                      | `https://tavdiiev.42.fr/`                                                                             |
| WordPress admin              | `https://tavdiiev.42.fr/wp-admin/`                                                                    |
| School host browser          | `https://tavdiiev.42.fr:8443/`                                                                        |
| School host Chrome test      | `google-chrome --user-data-dir=/tmp/chrome-test --host-resolver-rules="MAP tavdiiev.42.fr 127.0.0.1"` |
| ```                          |                                                                                                       |

