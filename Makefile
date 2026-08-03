.PHONY: build up down shell logs doctor sync-auth

build:
	docker compose build

up:
	docker compose up -d

down:
	docker compose down

shell:
	docker compose exec --user codex --workdir /workspace codex-workstation zsh

logs:
	docker compose logs --follow codex-workstation

doctor:
	docker compose exec --user codex codex-workstation codex app-server daemon version

sync-auth:
	docker compose exec --user root -e REPLACE_HOST_CONFIG=1 codex-workstation /usr/local/bin/seed-host-config
