.PHONY: build up down shell logs doctor sync-auth

build:
	docker compose -f docker/compose.yaml build --pull --build-arg CODEX_INSTALL_CACHE_BUST=$$(date +%s)

up:
	docker compose -f docker/compose.yaml up -d

down:
	docker compose -f docker/compose.yaml down

shell:
	docker compose -f docker/compose.yaml exec --user codex --workdir /workspace codex-workstation zsh

logs:
	docker compose -f docker/compose.yaml logs --follow codex-workstation

doctor:
	docker compose -f docker/compose.yaml exec --user codex codex-workstation codex app-server daemon version

sync-auth:
	docker compose -f docker/compose.yaml exec --user root -e REPLACE_HOST_CONFIG=1 codex-workstation /usr/local/bin/seed-host-config
