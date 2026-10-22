# Codex Container Workstation

A persistent Linux workstation for Codex CLI on macOS, built for Ghostty and
Codex desktop/mobile Remote Control. Docker and Podman are independent
implementations behind the same root-level Make interface.

## Choose an engine

Run this once after cloning:

```sh
make configure
```

Choose `docker` or `podman`. The selected engine is saved only in the ignored
`.container-engine` file, so every user can choose locally without changing the
repository. Afterwards both engines use the same commands:

```sh
make build
make up
make shell
make logs
make doctor
make sync-auth
make down
```

Run `make configure` again to change engines. CI and advanced users can
temporarily override the local selection, for example:

```sh
CONTAINER_ENGINE=podman make shell
```

## What is included

- Debian 13.6 slim, for Apple Silicon and Intel Macs
- Standalone Codex CLI and its managed remote-control app server
- AWS CLI 2.37.12, GitHub CLI (`gh`), Git, SSH client, `zsh`, and `tmux`
- Terraform, Python 3.13.16, Checkov, and Actionlint
- Persistent volumes for repositories, Codex, and GitHub state
- The local `~/.codex/skills` collection embedded into the image at build time

The AWS CLI default profile uses region `eu-west-1`. Override it inside the
container with `aws configure set region YOUR_REGION`.

The skills source defaults to `~/.codex/skills`; override it with
`CODEX_SKILLS_PATH` when building.

Ghostty is intentionally **not** in the Linux image. Containers cannot run the
native macOS application; use Ghostty on the host to enter the container.

## Start

1. Install and authenticate Codex on the Mac. If GitHub CLI has already been
   authenticated, its configuration is imported too; otherwise, authenticate it
   inside the workstation when needed.
2. Configure, build, and start the workstation:

   ```sh
   make configure
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
Codex daemon uses its authenticated relay; this workstation publishes no
inbound ports.

## Credential handling

The host's `~/.codex` and `~/.config/gh` are mounted read-only at
`/host-config`. On first startup, the entrypoint copies Codex's `auth.json` and
`config.toml`, plus GitHub CLI's `hosts.yml` and `config.yml`, into writable
named volumes. The container never writes to the host credential mounts.

When host credentials change, run `make sync-auth` while the container is up.
It refreshes only the copied credential/config files, then restarts the managed
Codex app-server so it reloads the new authentication state. Remote Control
clients reconnect briefly; the rest of the live Codex and GitHub state is
preserved.

If Codex presents the sign-in screen after credentials were synced, run:

```sh
make up
make sync-auth
make doctor
make shell
```

`make shell` expects the container to be running. `make sync-auth` now restarts
the managed app-server because `codex login status` only confirms the copied
credential cache, while an already-running app-server may still have the
previous authentication state in memory.
