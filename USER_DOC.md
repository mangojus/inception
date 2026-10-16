# USER-DOC — User Documentation

## What This Stack Provides

This project runs a self-hosted WordPress website with three services:

| Service   | Role                                                              |
|-----------|-------------------------------------------------------------------|
| nginx     | Receives HTTPS traffic on port 443, serves WordPress to browsers |
| WordPress | Runs the website application via PHP-FPM                         |
| MariaDB   | Stores all WordPress content, users, and settings                |

All three run as Docker containers on the same machine and communicate over a private internal network.

---

## Starting the Project

```bash
make
make build
make up
make start
```

This builds the images if needed and starts all three containers in the background. The first start takes longer — WordPress is downloading its core files and setting up the database.

Wait about 20–30 seconds after `make` completes before opening the site, to allow the database initialization to finish.

---

## Stopping the Project

```bash
make stop     # Stops containers,
make down     # Stops and removes containers, keeps all data intact
make clean    # Stops, removes containers and removes Docker volumes
make fclean   # Full reset — removes everything including site data
```

Use `make down` for day-to-day stopping. Only use `make fclean` if you want to start completely from scratch.

---

## Accessing the Website

Open your browser and go to:

```
https://rshin.42.fr
```

Your browser will show a security warning because the SSL certificate is self-signed. This is expected — click **Advanced** then **Proceed** (or in Chrome, type `thisisunsafe` anywhere on the warning page).

### WordPress Admin Panel

```
https://rshin.42.fr/wp-admin
```

Log in with the admin credentials stored in `secrets/credentials.txt`.

---

## Credentials

All passwords are stored as plain text files in the `secrets/` folder at the root of the project:

| File | Used for |
|---|---|
| `secrets/credentials.txt` | WordPress admin account password |
| `secrets/db_password.txt` | Database user password (used by WordPress internally) |
| `secrets/db_root_password.txt` | MariaDB root password (admin-level database access) |

The WordPress admin username and email are set in `srcs/.env`.

These files are never included in the Docker images and are not visible in container environment variables.

---

## Checking That Services Are Running

```bash
make status
```

All three services should show as `running` or `healthy`. Example expected output:

```
NAME        IMAGE                STATUS          PORTS
mariadb     mariadb:inception    healthy         3306/tcp
wordpress   wordpress:inception  running         9000/tcp
nginx       nginx:inception      running         0.0.0.0:443->443/tcp
```

If a service shows as `exited` or `unhealthy`, check its logs:

```bash
make logs
docker compose -f srcs/docker-compose.yml logs mariadb
docker compose -f srcs/docker-compose.yml logs wordpress
docker compose -f srcs/docker-compose.yml logs nginx
```

---

## Where Data Is Stored

All site data is stored on the host machine at:

| Data | Host path |
|---|---|
| WordPress files, themes, uploads | `/home/<USER>/data/wordpress` |
| Database contents | `/home/<USER>/data/mariadb` |

This data is preserved across restarts and `make down`. It is only deleted by `make fclean`.
