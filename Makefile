NAME = inception

all:
	@printf "Launch configuration $(NAME)...\n"
	@srcs/requirements/wordpress/tools/make_dir.sh
	@docker-compose -f ./srcs/docker-compose.yml --env-file srcs/.env up -d

build:
	@printf "Building configuration $(NAME)...\n"
	@bash srcs/requirements/wordpress/tools/make_dir.sh
	@docker-compose -f ./srcs/docker-compose.yml --env-file srcs/.env up -d --build

down:
	@printf "Stopping configuration $(NAME)...\n"
	@docker-compose -f ./srcs/docker-compose.yml --env-file srcs/.env down

re: down
	@printf "Rebuild configuration $(NAME)...\n"
	@docker-compose -f ./srcs/docker-compose.yml --env-file srcs/.env up -d --build

clean: down
    @printf "Cleaning configuration $(NAME)...\n"
    @docker system prune -a
    @sudo find ~/data/wordpress ~/data/mariadb -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +

fclean:
    @printf "Total clean of all configurations docker\n"
    @docker stop $$(docker ps -qa)
    @docker system prune --all --force --volumes
    @docker network prune --force
    @docker volume prune --force
    @sudo find ~/data/wordpress ~/data/mariadb -mindepth 1 -maxdepth 1 -exec rm -rf -- {} +

.PHONY: all build down re clean fclean
