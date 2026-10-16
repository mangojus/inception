_This project has been created as part of the 42 curriculum by rshin._

# Inception

A small production-style **WordPress** stack built entirely from custom Docker images: **nginx** (TLS), **WordPress + PHP-FPM**, and **MariaDB**. Each service runs in its own container on a private bridge network and is orchestrated with Docker Compose. No prebuilt service images are used.

```
            host :443 (HTTPS only)
                   │
          ┌────────▼────────┐
          │      nginx      │  TLS 1.2/1.3, self-signed cert
          └────────┬────────┘
                   │ FastCGI :9000        private bridge network "net"
          ┌────────▼────────┐
          │ WordPress + FPM │  installed and configured with WP-CLI
          └────────┬────────┘
                   │ :3306
          ┌────────▼────────┐
          │     MariaDB     │  healthchecked, initialized once
          └─────────────────┘
   bind mounts: /home/$USER/data/{wordpress,mariadb}
```

## Highlights

- **Custom images**: every Dockerfile starts from `debian:bookworm-slim`.
- **Single entry point**: only nginx publishes a port (`443`). WordPress and MariaDB are reachable only inside the Docker network.
- **Docker secrets** for the database root/user passwords and the WordPress admin password, mounted at `/run/secrets/` instead of being baked into images or env vars.
- **Idempotent entrypoints**: MariaDB initializes once (sentinel file), and WordPress checks each install step separately, so containers can restart safely without duplicating or corrupting data.
- **Ordered startup**: WordPress waits for MariaDB's healthcheck (`mariadb-admin ping`), and every service uses `restart: unless-stopped`.
- **Persistent data** in host bind mounts that survive `make down`.

## Quick start

Requirements: Docker Engine with Compose v2, `make`, and `sudo` for `/etc/hosts`.

**1. Point the domain to your machine**

```bash
echo "127.0.0.1 rshin.42.fr" | sudo tee -a /etc/hosts
```

**2. Create the secrets.** Each file holds a single password, with no trailing newline:

```bash
mkdir -p secrets
printf '%s' 'change-me-root'  > secrets/db_root_password.txt
printf '%s' 'change-me-db'    > secrets/db_password.txt
printf '%s' 'change-me-admin' > secrets/credentials.txt     # WordPress admin password
```

**3. Create `srcs/.env`** with the non-secret settings:

```bash
DOMAIN_NAME=rshin.42.fr
WP_TITLE=Inception
WP_ADMIN_USER=supervisor        # must not contain "admin"
WP_ADMIN_EMAIL=supervisor@example.com
WP_USER=author
WP_USER_EMAIL=author@example.com
WP_USER_PASSWORD=change-me-author
MYSQL_DATABASE=wordpress
MYSQL_USER=wp_user
```

Both `secrets/` and `.env` are git-ignored.

**4. Build and run**

```bash
make            # build images and start the stack
```

Then open **https://rshin.42.fr**. The certificate is self-signed, so expect a browser warning.

## Make targets

| Target | Action |
|---|---|
| `make` | create data dirs, build images (`--no-cache`), start containers |
| `make up` / `make down` | create and start / stop and remove containers |
| `make start` / `make stop` | start / stop existing containers |
| `make logs` / `make status` | follow logs / show container state |
| `make clean` | `down` and remove volumes |
| `make fclean` | also remove images and delete host data, then run `docker system prune -af`, which removes **all** unused Docker data on the machine, not just this project's |
| `make re` | `fclean` + `all` |

## Design notes

**Docker vs virtual machines.** A VM emulates a whole OS with its own kernel, so it's heavy and slow to boot. Containers share the host kernel and package only the app and its dependencies, so they start in milliseconds and build reproducibly. The tradeoff is weaker isolation, since a host kernel vulnerability affects every container.

**Secrets vs environment variables.** Environment variables are visible through `docker inspect` and in the process environment, so they're used only for non-sensitive settings like domain, database name and usernames. Passwords are passed as Docker secrets, which are mounted files that never appear in image layers or in `docker inspect`.

**Bridge network vs host network.** With host networking a container shares the host's interfaces and gets no isolation. The bridge network gives each container its own address, lets services reach each other by name (`wordpress`, `mariadb`), and exposes only explicitly published ports.

**Volumes vs bind mounts.** Named volumes are managed by Docker and stored opaquely. Bind mounts map a known host path, which can be inspected and backed up directly. This project uses bind mounts because the subject requires data to live under `/home/<login>/data`.

## Documentation

- [`USER_DOC.md`](USER_DOC.md): using the site, accessing the admin panel, credentials
- [`DEV_DOC.md`](DEV_DOC.md): project layout, setup from scratch, container management, troubleshooting

## Resources

- [Docker: Get started](https://docs.docker.com/get-started/)
- [Choosing the right Docker base image](https://oneuptime.com/blog/post/2026-02-08-how-to-choose-the-right-docker-base-image-for-your-application/view)
- [MariaDB: creating a custom container image](https://mariadb.com/docs/server/server-management/automated-mariadb-deployment-and-administration/docker-and-mariadb/creating-a-custom-container-image)

AI was used in line with 42's AI rules: VM, Docker and shell setup questions; reviewing config syntax and the weak points of the setup; and finishing the documentation files.
