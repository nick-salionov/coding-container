.PHONY: help build up down shell logs doctor sync-auth docker-build docker-up docker-down docker-shell docker-logs docker-doctor docker-sync-auth podman-build podman-up podman-down podman-shell podman-logs podman-doctor podman-sync-auth validate

IMAGE := codex-workstation:local
CONTAINER := codex-workstation
CODEX_SKILLS_PATH ?= $(HOME)/.codex/skills
HOST_CODEX_PATH ?= $(HOME)/.codex
HOST_GH_PATH ?= $(HOME)/.config/gh
HOST_CONFIG_VOLUMES := $(if $(wildcard $(HOST_CODEX_PATH)),--volume "$(HOST_CODEX_PATH):/host-config/codex:ro") $(if $(wildcard $(HOST_GH_PATH)),--volume "$(HOST_GH_PATH):/host-config/gh:ro")

help:
	@printf '%s\n' 'Use either Docker or Podman explicitly:' \
		'  make docker-build docker-up docker-shell' \
		'  make podman-build podman-up podman-shell' \
		'' \
		'Unprefixed targets remain Podman aliases for existing users.'

# Backwards-compatible Podman aliases.
build: podman-build

up: podman-up

down: podman-down

shell: podman-shell

logs: podman-logs

doctor: podman-doctor

sync-auth: podman-sync-auth

docker-build:
	docker build --pull --file Containerfile --tag $(IMAGE) --build-context codex-skills="$(CODEX_SKILLS_PATH)" --build-arg CODEX_INSTALL_CACHE_BUST=$$(date +%s) .

docker-up:
	@if docker container inspect $(CONTAINER) >/dev/null 2>&1; then \
		docker start $(CONTAINER); \
	else \
		docker run --detach --name $(CONTAINER) --init --restart unless-stopped --workdir /workspace \
			--volume workspace:/workspace \
			--volume codex-state:/home/codex/.codex \
			--volume gh-state:/home/codex/.config/gh \
			$(HOST_CONFIG_VOLUMES) \
			$(IMAGE); \
	fi

docker-down:
	@if docker container inspect $(CONTAINER) >/dev/null 2>&1; then docker rm --force $(CONTAINER); fi

docker-shell:
	@restore_ghostty_colors() { \
		printf "\033]111\033\\"; \
	}; \
	printf "\033]11;#081a33\033\\"; \
	trap restore_ghostty_colors 0; \
	docker exec --interactive --tty --env COLORTERM=truecolor --user codex --workdir /workspace $(CONTAINER) zsh

docker-logs:
	docker logs --follow $(CONTAINER)

docker-doctor:
	docker exec --user codex $(CONTAINER) codex app-server daemon version

docker-sync-auth:
	docker exec --user root --env REPLACE_HOST_CONFIG=1 $(CONTAINER) /usr/local/bin/seed-host-config

podman-build:
	podman build --pull=always --file Containerfile --tag $(IMAGE) --build-context codex-skills="$(CODEX_SKILLS_PATH)" --build-arg CODEX_INSTALL_CACHE_BUST=$$(date +%s) .

podman-up:
	@if podman container exists $(CONTAINER); then \
		podman start $(CONTAINER); \
	else \
		podman run --detach --name $(CONTAINER) --init --restart unless-stopped --workdir /workspace \
			--volume workspace:/workspace:Z \
			--volume codex-state:/home/codex/.codex:Z \
			--volume gh-state:/home/codex/.config/gh:Z \
			$(HOST_CONFIG_VOLUMES) \
			$(IMAGE); \
	fi

podman-down:
	@if podman container exists $(CONTAINER); then podman rm --force $(CONTAINER); fi

podman-shell:
	@restore_ghostty_colors() { \
		printf "\033]111\033\\"; \
	}; \
	printf "\033]11;#081a33\033\\"; \
	trap restore_ghostty_colors 0; \
	podman exec --interactive --tty --env COLORTERM=truecolor --user codex --workdir /workspace $(CONTAINER) zsh

podman-logs:
	podman logs --follow $(CONTAINER)

podman-doctor:
	podman exec --user codex $(CONTAINER) codex app-server daemon version

podman-sync-auth:
	podman exec --user root --env REPLACE_HOST_CONFIG=1 $(CONTAINER) /usr/local/bin/seed-host-config

validate:
	@test -f Containerfile
	@test -f .dockerignore
	@test -f .containerignore
	@$(MAKE) --no-print-directory help
