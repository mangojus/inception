FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV NGINX_VERSION=1.22.1-9+deb12u7

RUN apt-get update && apt-get install -y \
	nginx=${NGINX_VERSION} \
	openssl \
	&& rm -rf /var/lib/apt/lists/*

RUN	mkdir -p /etc/nginx/ssl /var/www/html

COPY default.conf /etc/nginx/conf.d/default.conf
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["nginx", "-g", "daemon off;"]
