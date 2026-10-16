#!/bin/bash
set -e

DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)
DB_PASSWORD=$(cat /run/secrets/db_password)

mkdir -p /run/mysqld
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

if [ ! -f /var/lib/mysql/.inception_init ]; then
	echo "First run — initializing MariaDB..."
	mariadb-install-db --user=mysql --datadir=/var/lib/mysql --skip-test-db
	mariadbd --user=mysql --datadir=/var/lib/mysql --skip-networking &
	MARIADB_PID=$!

	until mariadb-admin ping --silent 2>/dev/null; do
		echo "Waiting for MariaDB..."
		sleep 1
	done

	mariadb -u root <<-EOF
		ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';
		CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
		CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
		GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
		FLUSH PRIVILEGES;
	EOF

	touch /var/lib/mysql/.inception_init

	mariadb-admin -u root -p"${DB_ROOT_PASSWORD}" shutdown
	wait $MARIADB_PID
	echo "Initialization complete."
else
	echo "Database already initialized, skipping."
fi

exec mariadbd --user=mysql --console
