.PHONY: build up down shell logs doctor sync-auth

IMAGE := codex-workstation:local
CONTAINER := codex-workstation
CODEX_SKILLS_PATH ?= $(HOME)/.codex/skills
HOST_CODEX_PATH ?= $(HOME)/.codex
HOST_GH_PATH ?= $(HOME)/.config/gh
HOST_CONFIG_VOLUMES := $(if $(wildcard $(HOST_CODEX_PATH)),--volume "$(HOST_CODEX_PATH):/host-config/codex:ro") $(if $(wildcard $(HOST_GH_PATH)),--volume "$(HOST_GH_PATH):/host-config/gh:ro")

build:
	podman build --pull=always --ignorefile podman/.containerignore --file podman/Containerfile --tag $(IMAGE) --build-context codex-skills="$(CODEX_SKILLS_PATH)" --build-arg CODEX_INSTALL_CACHE_BUST=$$(date +%s) podman

up:
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

down:
	@if podman container exists $(CONTAINER); then podman rm --force $(CONTAINER); fi

shell:
	@restore_ghostty_colors() { \
		printf '\033]111\033\\'; \
	}; \
	printf '\033]11;#081a33\033\\'; \
	trap restore_ghostty_colors 0; \
	podman exec --interactive --tty --env COLORTERM=truecolor --user codex --workdir /workspace $(CONTAINER) zsh

logs:
	podman logs --follow $(CONTAINER)

doctor:
	podman exec --user codex $(CONTAINER) codex app-server daemon version

sync-auth:
	podman exec --user root --env REPLACE_HOST_CONFIG=1 $(CONTAINER) /usr/local/bin/seed-host-config
