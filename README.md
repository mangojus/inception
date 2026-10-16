_This project has been created as part of the 42 curriculum by <rshin>._

# Inception

## Description

This project aims to acquire a deeper understanding of Docker and containerization in general.
The goal is to build from the ground up your own Docker images, learn how to organize the folder structure in a coherent manner, and to document how and why it is useful in real environments.
The stack consists of three services — nginx, WordPress, and MariaDB — each running in its own container, communicating over a private Docker network, with data persisted through bind-mounted volumes.

## Instructions

- git clone https://github.com/mangojus/inception.git
- import secrets and .env file
- make to build and launch docker images/containers
- go to https://rshin.42.fr
- make stop to stop container
- make start to start if containers are not removed
- make down to stop and remove containers
- make up to create containers and start
- make clean to remove virtual volumes
- make fclean to remove everything including bound volumes

## Project Description

### Why Docker

Each service in this project runs in an isolated container built from a custom Dockerfile, based on debian:bookworm-slim. Using Docker means the environment is fully reproducible — the same images build and run identically on any machine. It also enforces separation of concerns: nginx handles TLS termination and request routing, WordPress handles application logic, and MariaDB handles data storage. Each can be rebuilt, restarted, or debugged independently without affecting the others.

### Services and Sources

nginx serves as the sole entry point to the stack. It listens on port 443, terminates TLS using a self-signed certificate generated at runtime, and forwards PHP requests to WordPress over FastCGI. No traffic reaches WordPress or MariaDB directly from outside the Docker network.
WordPress runs as a PHP-FPM process. The application files are downloaded at first startup using WP-CLI, configured to connect to MariaDB, and installed with an admin account and a secondary author account. It does not bind any port to the host — only nginx can reach it, via the internal Docker network on port 9000.
MariaDB stores all WordPress data: posts, users, settings, and media metadata. It is initialized on first boot with a dedicated database and user. The root account is password-protected. Like WordPress, it is not reachable from outside the Docker network.

### Main Design Choices

Debian bookworm version, old but stable, also lightweight and heavily documented.
Secrets over environment variables for passwords. All passwords are injected via Docker secrets (files mounted at /run/secrets/) rather than environment variables. Environment variables are used only for non-sensitive configuration such as database name, domain, and usernames.
Idempotent entrypoints. Each entrypoint script checks whether its setup has already run before doing anything. MariaDB checks for a sentinel file. WordPress checks for wp-load.php, wp-config.php, and whether core is installed — each step independently. Containers can be restarted safely at any point without corrupting or duplicating data.

### Virtual Machines vs Docker

A virtual machine emulates an entire operating system on top of a hypervisor, with its own kernel, drivers, and hardware abstraction. It is heavy, slow to start, and consumes significant memory and disk space.
Docker containers share the host kernel and only package the application and its dependencies. They start in milliseconds, use far less memory, and are reproducible across environments. The tradeoff is that containers are less isolated than VMs — a kernel vulnerability on the host affects all containers.
For development and service orchestration, Docker is almost always the right choice. For strong security isolation or running a different OS, VMs are still appropriate.

### Secrets vs Environment Variables

Environment variables are passed into a container at runtime and are visible to anyone with access to docker inspect or the process environment. They are fine for non-sensitive configuration like database names or domain names.
Secrets are files mounted into the container at /run/secrets/ by Docker's secrets mechanism. They are never stored in environment variables, never appear in image layers, and are not visible in docker inspect. Passwords, API keys, and any sensitive credential should always use secrets rather than environment variables.

### Docker Network vs Host Network

With host networking, the container shares the host's network interface directly. Any port the container opens is immediately accessible on the host — no mapping needed, but no isolation either.
With a Docker bridge network (used in this project), containers get their own virtual network. They can reach each other by service name (e.g. wordpress, mariadb) and are isolated from the outside world. Only explicitly published ports (e.g. 443:443) are accessible from the host. This is more secure and mirrors a real production environment.

### Docker Volumes vs Bind Mounts

A Docker volume is managed by Docker itself — data lives in Docker's internal storage area and is opaque to the host filesystem. It is portable and easy to back up via Docker commands.
A bind mount maps a specific host directory into the container. The data lives at a known path on the host (e.g. /home/rshin/data/wordpress) and can be inspected, backed up, or edited directly without Docker commands. This project uses bind mounts to satisfy the 42 requirement that data persists at a specific location on the host machine.

## Resources

- Docs:
    - https://docs.docker.com/get-started/
    - https://oneuptime.com/blog/post/2026-02-08-how-to-choose-the-right-docker-base-image-for-your-application/view
    - https://mariadb.com/docs/server/server-management/automated-mariadb-deployment-and-administration/docker-and-mariadb/creating-a-custom-container-image
- AI:
    - Setup:
        - VM setup
        - Docker setup
        - bash/git commands
    - Curiosity/Quirks:
        - Examples of data we find in .env / 
        - Show me what a normal .conf
        - Pros & Cons
    - Debugging:
        - Is the syntax correct in my configs ?
        - Are there better refactor/tool alternatives ? (optimize/clean/secure)
        - Are the names/files coherent ?
        - What is the weakness of my setup ?
        - How would I do this differently ?
    - Documentation files:
        - Help me complete documentation files, I already filled the most important.
