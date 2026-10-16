FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV MARIADB_VERSION=1:10.11.14-0+deb12u2

RUN apt-get update && apt-get install -y \
		mariadb-server=${MARIADB_VERSION} \
		mariadb-client=${MARIADB_VERSION} \
		&& rm -rf /var/lib/apt/lists/*

RUN mkdir -p /var/lib/mysql \
	&& chown -R mysql:mysql /var/lib/mysql
		
RUN mkdir -p /run/mysqld \
	&& chown -R mysql:mysql /run/mysqld \
	&& chmod 755 /run/mysqld

RUN sed -i 's|bind-address.*|bind-address = 0.0.0.0|' /etc/mysql/mariadb.conf.d/50-server.cnf

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
