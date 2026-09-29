NAME = inception

all:
	@printf "Launch configuration $(NAME)...\n"
	@srcs/requirements/wordpress/tools/make_dir.sh
	@docker-compose -f ./srcs/docker-compose.yml --env-file srcs/.env up -d
	@sudo chmod 755 /home/${USER}/data/mariadb

build:
	@printf "Building configuration $(NAME)...\n"
	@srcs/requirements/wordpress/tools/make_dir.sh
	@srcs/requirements/nginx/tools/generate_cert.sh
	@docker-compose -f ./srcs/docker-compose.yml --env-file srcs/.env up -d --build
	@sudo chmod 755 /home/${USER}/data/mariadb

down:
	@printf "Stopping configuration $(NAME)...\n"
	@docker-compose -f ./srcs/docker-compose.yml --env-file srcs/.env down

re: down
	@printf "Rebuild configuration $(NAME)...\n"
	@docker-compose -f ./srcs/docker-compose.yml --env-file srcs/.env up -d --build

clean: down
	@printf "Cleaning configuration $(NAME)...\n"
	@docker system prune -a

fclean:
	@printf "Total clean of all configurations docker\n"
	@docker stop $$(docker ps -qa)
	@docker system prune --all --force --volumes
	@docker network prune --force
	@docker volume prune --force
	@sudo rm -rf /home/${USER}/data/*
.PHONY: all build down re clean fclean
