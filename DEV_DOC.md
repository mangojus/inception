# DEV-DOC — Developer Documentation

## Prerequisites

- Docker Engine 20.10+
- Docker Compose v2 (included with Docker Desktop or installable via `apt`)
- `make`
- A host entry pointing your domain to localhost

Add to `/etc/hosts`:
```
127.0.0.1   rshin.42.fr
```

---

## Project Structure

```
inception/
├── Makefile
├── secrets/                    # Secret files — never commit these
│   ├── credentials.txt         # WordPress admin password
│   ├── db_password.txt         # MariaDB user password
│   └── db_root_password.txt    # MariaDB root password
└── srcs/
    ├── .env                    # Non-sensitive environment variables
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        │   ├── Dockerfile
        │   ├── default.conf    # nginx server block (TLS + PHP-FPM proxy)
        │   ├── entrypoint.sh   # Generates self-signed SSL cert at runtime
        │   └── .dockerignore
        ├── wordpress/
        │   ├── Dockerfile
        │   └── entrypoint.sh   # Downloads WP core, creates config, installs site
        └── mariadb/
            ├── Dockerfile
            └── entrypoint.sh   # Initializes DB, creates user, sets root password
```

---

## Environment Configuration

Copy and fill in `srcs/.env`:

Passwords are **not** stored in `.env` — they go in secrets files.

---

## Secrets Setup

Each file contains a single password with no trailing newline:

```bash
cat secrets/db_root_password.txt
cat secrets/db_password.txt
cat secrets/credentials.txt
```

These are mounted into containers at `/run/secrets/` by Docker Compose and read via `cat /run/secrets/<filename>` in entrypoint scripts. They are never passed as environment variables.

---

## Build and Launch

```bash
make          # Creates data directories, builds images, starts containers
make down     # Stops containers (preserves volumes)
make clean    # Stops containers and removes volumes
make fclean   # Full teardown: stops, removes images, deletes host data
make re       # fclean + full rebuild
make logs     # Follow logs for all services
make status   # Show running containers and health
```

Internally, `make` maps to:

```bash
# build target
mkdir -p /home/$(USER)/data/wordpress
mkdir -p /home/$(USER)/data/mariadb
docker compose -f srcs/docker-compose.yml build --no-cache

# up target
docker compose -f srcs/docker-compose.yml up -d
```

---

## Container Management

```bash
# Follow logs for a specific service
docker compose -f srcs/docker-compose.yml logs -f mariadb
docker compose -f srcs/docker-compose.yml logs -f wordpress
docker compose -f srcs/docker-compose.yml logs -f nginx

# Open a shell inside a running container
docker exec -it nginx bash
docker exec -it wordpress bash
docker exec -it mariadb bash

# Inspect a container's environment (note: secrets are NOT visible here)
docker inspect mariadb
```

---

## Data Persistence

Host paths where data is stored:

| Service   | Host path                        | Container path      |
|-----------|----------------------------------|---------------------|
| WordPress | `/home/<USER>/data/wordpress`    | `/var/www/html`     |
| MariaDB   | `/home/<USER>/data/mariadb`      | `/var/lib/mysql`    |

These are bind mounts defined in `docker-compose.yml`. Data survives container restarts and `docker compose down`. Only `make fclean` deletes them.

---

## Service Startup Order

Docker Compose enforces the following dependency chain:

```
nginx → wordpress → mariadb
```

- `mariadb` has a healthcheck (`mariadb-admin ping`). WordPress waits for `service_healthy`.
- `nginx` waits for `service_started` on wordpress (PHP-FPM socket readiness is handled inside the entrypoint).

On first boot, MariaDB's entrypoint runs `mariadb-install-db`, starts a temporary instance, creates the database and user, then shuts down cleanly before the final `exec mariadbd`. A sentinel file `/var/lib/mysql/.inception_init` prevents this from running again on subsequent starts.

Similarly, WordPress's entrypoint checks for the presence of `wp-load.php`, `wp-config.php`, and whether core is installed before running each step — making it fully idempotent.

---

## SSL Certificate

The nginx entrypoint generates a self-signed certificate at container startup using `openssl`. The certificate is stored inside the container at `/etc/nginx/ssl/`. It uses `$DOMAIN_NAME` from the environment for the Common Name field.

Because it is self-signed, browsers will show a security warning — this is expected for a local development setup. To bypass it in Chrome, type `thisisunsafe` on the warning page.

---

## Rebuilding a Single Service

```bash
docker compose -f srcs/docker-compose.yml build --no-cache wordpress
docker compose -f srcs/docker-compose.yml up -d --no-deps wordpress
```

---

## Common Issues

| Symptom | Likely cause | Fix |
|---|---|---|
| `connection refused` on port 443 | nginx not started | `make logs` to check nginx errors |
| WordPress shows DB connection error | mariadb not ready yet | Wait a few seconds, check `make status` |
| `wp-config.php` not created | Wrong DB credentials in secrets | Check `secrets/db_password.txt` matches `.env` `MYSQL_USER` |
| Page redirects to wrong domain | `DOMAIN_NAME` mismatch | Ensure `.env` and `/etc/hosts` use the same value |
