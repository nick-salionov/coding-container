# Codex Container Workstation

A persistent, local Linux workstation for Codex CLI on macOS. It is designed for
Ghostty as the local terminal and Codex desktop/mobile Remote Control for working
away from the Mac.

## What is included

- Debian 13.6 (Trixie) slim, for Apple Silicon and Intel Macs
- Standalone Codex CLI and its managed remote-control app server
- GitHub CLI (`gh`), Git, SSH client, `zsh`, and `tmux`
- Terraform, Python 3.14, Checkov, and Actionlint
- Docker- or Podman-managed persistent volumes for repositories, Codex, and GitHub state
- The local `~/.codex/skills` collection embedded into the image at build time

The skills source defaults to `~/.codex/skills`; override it with
`CODEX_SKILLS_PATH` when building. Both runtimes use the same `Containerfile`,
entrypoint scripts, image tag, volume names, and command interface; the
`Makefile` owns the small runtime-specific differences.

Ghostty is intentionally **not** in the Linux image. Containers cannot run the
native macOS application; use Ghostty on the host to enter the container.

## Start

1. Install and authenticate Codex on the Mac. If GitHub CLI has already been
   authenticated, its configuration is imported too; otherwise, authenticate it
   from inside the workstation when needed.
2. Choose your container runtime, then build and start the persistent
   workstation:

   ```sh
   # Docker
   make docker-build docker-up

   # or Podman
   make podman-build podman-up
   ```

3. Open it from Ghostty:

   ```sh
   make docker-shell  # or: make podman-shell
   ```

4. Clone and work on repositories under `/workspace`.

   ```sh
   cd /workspace
   gh repo clone OWNER/REPOSITORY
   cd REPOSITORY
   codex
   ```

5. Verify the managed Codex app-server:

   ```sh
   make doctor
   ```

Remote Control is enabled during startup. Use a current Codex desktop/mobile
client signed into the same account to connect to the running environment. The
Codex daemon uses its authenticated relay; this workstation publishes no
inbound ports.

## Credential handling

The host's `~/.codex` and `~/.config/gh` are mounted read-only at
`/host-config`. On first startup, the entrypoint copies Codex's `auth.json` and
`config.toml`, plus GitHub CLI's `hosts.yml` and `config.yml`, into writable
named volumes. The macOS-only `node_repl` MCP entry is excluded because its
ChatGPT-app executable is unavailable in Linux. The container never writes to
the host credential mounts.

When host credentials change, run `make docker-sync-auth` or
`make podman-sync-auth` while the container is up.
It refreshes only the four copied credential/config files; the rest of the
live Codex and GitHub state is preserved.

## Operations

```sh
make docker-logs    # follow startup and daemon logs
make docker-down    # stop; all work and state remain in named volumes
make docker-up      # start again
```

Replace `docker-` with `podman-` for a Podman environment. The unprefixed
targets (`make build`, `make up`, and so on) remain Podman aliases for
backwards compatibility.

## Runtime support

Docker and Podman each have explicit targets rather than separate, duplicated
Dockerfiles or Compose definitions. The only intentional difference is Podman’s
`:Z` volume labels, which support SELinux hosts. This design keeps the runtime
selection visible in commands while making image and startup behavior testable
from one shared source of truth.

The remote-control daemon lifecycle is experimental upstream. Keep the image
fresh by rebuilding periodically and run `make docker-doctor` or
`make podman-doctor` after upgrades.
