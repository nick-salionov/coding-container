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
make login
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

1. Install Codex on the Mac. If GitHub CLI has already been
   authenticated, its configuration is imported too; otherwise, authenticate it
   inside the workstation when needed.
2. Configure, build, and start the workstation:

   ```sh
   make configure
   make build
   make up
   ```

3. Create an independent container login using the Mac's normal browser flow:

   ```sh
   make login
   ```

   This works for headless containers even when your organization disables
   device-code authentication. Run it on the computer with your browser and
   access to the configured Docker or Podman connection.

4. Open it from Ghostty:

   ```sh
   make shell
   ```

5. Clone and work on repositories under `/workspace`.

   ```sh
   cd /workspace
   gh repo clone OWNER/REPOSITORY
   cd REPOSITORY
   codex
   ```

6. Verify the managed Codex app-server:

   ```sh
   make doctor
   ```

Remote Control is enabled during startup. Use a current Codex desktop/mobile
client signed into the same account to connect to the running environment. The
Codex daemon uses its authenticated relay; this workstation publishes no
inbound ports.

## Credential handling

The host's `~/.codex` and `~/.config/gh` are mounted read-only at
`/host-config`. On first startup, the entrypoint copies Codex's `auth.json` (if available) and
`config.toml`, plus GitHub CLI's `hosts.yml` and `config.yml`, into writable
named volumes. The container never writes to the host credential mounts.

Use `make login` for Codex authentication. It creates a fresh login in a temporary
local `CODEX_HOME`, imports the resulting `auth.json` into the container as the
`codex` user, restarts the managed app-server, and removes the temporary local
cache. Your normal Mac login is preserved. The container keeps its own session
in the persistent `codex-state` volume and refreshes it during normal use.

When host configuration or GitHub credentials change, run `make sync-auth` while
the container is up. It refreshes the copied configuration and GitHub files,
preserves an existing Codex `auth.json`, and restarts the managed app-server.
Repeatedly overwriting the container's refreshed tokens with the Mac's copy can
break authentication; each environment should maintain its own session.

If Codex asks you to sign in again, run on the Mac:

```sh
make up
make login
make doctor
make shell
```

`make shell` and `make login` expect the container to be running. Rebuild and
recreate existing containers after updating the seeding script so `sync-auth`
uses the token-preserving behavior. Named volumes retain repositories and state.
