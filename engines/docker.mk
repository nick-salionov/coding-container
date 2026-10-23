.PHONY: build up down shell logs doctor login sync-auth

build:
	docker compose -f docker/compose.yaml build --pull --build-arg CODEX_INSTALL_CACHE_BUST=$$(date +%s)

up:
	docker compose -f docker/compose.yaml up -d

down:
	docker compose -f docker/compose.yaml down

shell:
	@restore_ghostty_colors() { \
		printf '\033]111\033\\'; \
	}; \
	printf '\033]11;#081a33\033\\'; \
	trap restore_ghostty_colors 0; \
	docker compose -f docker/compose.yaml exec --env COLORTERM=truecolor --user codex --workdir /workspace codex-workstation zsh

logs:
	docker compose -f docker/compose.yaml logs --follow codex-workstation

doctor:
	docker compose -f docker/compose.yaml exec --user codex codex-workstation codex app-server daemon version

login:
	bash scripts/login-codex docker codex-workstation

sync-auth:
	docker compose -f docker/compose.yaml exec --user root -e REPLACE_HOST_CONFIG=1 codex-workstation /usr/local/bin/seed-host-config
	docker compose -f docker/compose.yaml exec --user codex codex-workstation codex app-server daemon restart
