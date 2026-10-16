#!/bin/bash
set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/credentials)

mkdir -p /run/php

if [ ! -f /var/www/html/wp-load.php ]; then
	echo "Downloading WordPress..."
	wp core download \
		--path=/var/www/html \
		--allow-root
else
	echo "WordPress core already present, skipping download."
fi

if [ ! -f /var/www/html/wp-config.php ]; then
	echo "Creating wp-config.php..."
    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$DB_PASSWORD" \
        --dbhost=mariadb \
        --path=/var/www/html \
        --allow-root
    wp config shuffle-salts \
        --path=/var/www/html \
		--allow-root
else
	echo "wp-config.php already exists, skipping."
fi

if ! wp core is-installed --path=/var/www/html --allow-root; then
	echo "Installing WordPress..."
	wp core install \
		--url="$DOMAIN_NAME" \
		--title="$WP_TITLE" \
		--admin_user="$WP_ADMIN_USER" \
		--admin_password="$WP_ADMIN_PASSWORD" \
		--admin_email="$WP_ADMIN_EMAIL" \
		--skip-email \
		--path=/var/www/html \
		--allow-root
else
	echo "WordPress already installed, skipping."
fi

if ! wp user get "$WP_USER" --path=/var/www/html --allow-root &>/dev/null; then
	echo "Creating secondary user..."
    wp user create "$WP_USER" "$WP_USER_EMAIL" \
        --role=author \
        --user_pass="$WP_USER_PASSWORD" \
        --path=/var/www/html \
        --allow-root
else
	echo "Secondary user already exists, skipping."
fi 

exec "$@"
