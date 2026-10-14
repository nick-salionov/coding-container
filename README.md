# Codex Docker Workstation

A persistent, local Linux workstation for Codex CLI on macOS. It is designed for
Ghostty as the local terminal and Codex desktop/mobile Remote Control for working
away from the Mac.

## What is included

- Debian 13.6 (Trixie) slim, for Apple Silicon and Intel Macs
- Standalone Codex CLI and its managed remote-control app server
- GitHub CLI (`gh`), Git, SSH client, `zsh`, and `tmux`
- Terraform, Python 3.14, Checkov, and Actionlint
- Docker-managed persistent volumes for repositories, Codex, and GitHub state
- The local `~/.codex/skills` collection embedded into the image at build time

The skills source defaults to `~/.codex/skills`; override it with `CODEX_SKILLS_PATH` when building.

Ghostty is intentionally **not** in the Linux image. Docker Desktop containers
cannot run the native macOS application; use Ghostty on the host to enter the
container.

## Start

1. Install and authenticate Codex and GitHub CLI on the Mac. The configuration
   folders must exist: `~/.codex` and `~/.config/gh`.
2. Build and start the persistent workstation:

   ```sh
   make build
   make up
   ```

3. Open it from Ghostty:

   ```sh
   make shell
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
Codex daemon uses its authenticated relay; this Compose service publishes no
inbound ports.

## Credential handling

The host's `~/.codex` and `~/.config/gh` are mounted read-only at
`/host-config`. On first startup, the entrypoint copies only Codex's `auth.json`
and `config.toml`, plus GitHub CLI's `hosts.yml` and `config.yml`, into writable
named volumes. The container never writes to the host credential mounts.

When host credentials change, run `make sync-auth` while the container is up.
It refreshes only the four copied credential/config files; the rest of the
live Codex and GitHub state is preserved.

## Operations

```sh
make logs    # follow startup and daemon logs
make down    # stop; all work and state remain in named volumes
make up      # start again
```

The remote-control daemon lifecycle is experimental upstream. Keep the image
fresh by rebuilding periodically and run `make doctor` after upgrades.
