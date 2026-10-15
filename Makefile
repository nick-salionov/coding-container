.DEFAULT_GOAL := help

ENGINE_CONFIG := .container-engine
VALID_ENGINES := docker podman

-include $(ENGINE_CONFIG)

.PHONY: help configure

help:
	@printf '%s\n' \
		'Choose an engine once with: make configure' \
		'Then use the same commands for either engine:' \
		'  make build  make up  make shell  make logs  make down'

configure:
	@default=docker; \
	if ! command -v docker >/dev/null 2>&1 && command -v podman >/dev/null 2>&1; then default=podman; fi; \
	printf 'Container engine (docker/podman) [%s]: ' "$$default"; \
	read -r engine; \
	engine=$${engine:-$$default}; \
	case "$$engine" in \
		docker|podman) printf 'CONTAINER_ENGINE=%s\n' "$$engine" > $(ENGINE_CONFIG) ;; \
		*) printf '%s\n' 'Engine must be docker or podman.' >&2; exit 2 ;; \
	esac; \
	printf 'Configured %s. Run make help for commands.\n' "$$engine"

ifneq ($(filter-out configure help,$(MAKECMDGOALS)),)
ifndef CONTAINER_ENGINE
$(error No engine configured. Run `make configure` first)
endif
ifneq ($(filter $(CONTAINER_ENGINE),$(VALID_ENGINES)),$(CONTAINER_ENGINE))
$(error CONTAINER_ENGINE must be one of: $(VALID_ENGINES))
endif
include engines/$(CONTAINER_ENGINE).mk
endif
