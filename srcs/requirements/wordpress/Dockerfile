FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PHP_VERSION=2:8.2+93

RUN apt-get update && apt-get install -y \
	php-fpm=${PHP_VERSION} \
	php-mysql=${PHP_VERSION} \
	php-curl=${PHP_VERSION} \
	php-gd=${PHP_VERSION} \
	curl \
	&& rm -rf /var/lib/apt/lists/*

RUN	curl -O  https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x wp-cli.phar \
	&& mv wp-cli.phar /usr/local/bin/wp

RUN sed -i 's|listen = .*|listen = 0.0.0.0:9000|' /etc/php/8.2/fpm/pool.d/www.conf

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm8.2", "-F"]
