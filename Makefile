NAME = inception

# PATHING

COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR = /home/$(USER)/data
SECRETS_DIR = secrets

# TARGET RULES

all: build up

build:
	mkdir -p $(DATA_DIR)/wordpress
	mkdir -p $(DATA_DIR)/mariadb
	docker compose -f $(COMPOSE_FILE) build --no-cache

up:
	docker compose -f $(COMPOSE_FILE) up -d

down:
	docker compose -f $(COMPOSE_FILE) down

start:
	docker compose -f $(COMPOSE_FILE) start

stop:
	docker compose -f $(COMPOSE_FILE) stop

clean: down
	docker compose -f $(COMPOSE_FILE) down -v

fclean: clean
	docker compose -f $(COMPOSE_FILE) down --rmi all
	docker run --rm -v $(DATA_DIR):/data alpine \
		sh -c "rm -rf /data/wordpress /data/mariadb"
	docker system prune -af

re: fclean all

logs:
	docker compose -f $(COMPOSE_FILE) logs -f

status:
	docker compose -f $(COMPOSE_FILE) ps

.PHONY: all build up down clean fclean re logs status
