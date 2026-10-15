FROM debian:13.6-slim

ARG CODEX_INSTALL_URL=https://chatgpt.com/codex/install.sh
ARG ACTIONLINT_VERSION=1.7.12
ARG TARGETARCH

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    HOME=/home/codex \
    CODEX_HOME=/home/codex/.codex \
    PATH=/home/codex/.local/bin:${PATH}

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        ca-certificates \
        bubblewrap \
        curl \
        git \
        gh \
        gpg \
        gosu \
        micro \
        openssh-client \
        procps \
        tmux \
        zsh \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 1000 codex \
    && useradd --uid 1000 --gid codex --create-home --shell /usr/bin/zsh codex

# Install the official Actionlint release for the image architecture.
RUN case "$TARGETARCH" in \
        amd64) actionlint_arch=amd64; actionlint_sha256=8aca8db96f1b94770f1b0d72b6dddcb1ebb8123cb3712530b08cc387b349a3d8 ;; \
        arm64) actionlint_arch=arm64; actionlint_sha256=325e971b6ba9bfa504672e29be93c24981eeb1c07576d730e9f7c8805afff0c6 ;; \
        *) echo "Unsupported Actionlint architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac \
    && curl --fail --silent --show-error --location \
        "https://github.com/rhysd/actionlint/releases/download/v${ACTIONLINT_VERSION}/actionlint_${ACTIONLINT_VERSION}_linux_${actionlint_arch}.tar.gz" \
        -o /tmp/actionlint.tar.gz \
    && echo "${actionlint_sha256}  /tmp/actionlint.tar.gz" | sha256sum --check --status - \
    && tar --extract --gzip --file /tmp/actionlint.tar.gz --directory /tmp \
    && install --mode=0755 /tmp/actionlint /usr/local/bin/actionlint \
    && rm -f /tmp/actionlint.tar.gz /tmp/actionlint \
    && actionlint -version

# Install Terraform from HashiCorp's signed Debian repository.
RUN curl --fail --silent --show-error --location https://apt.releases.hashicorp.com/gpg \
        | gpg --dearmor --output /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    && . /etc/os-release \
    && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $VERSION_CODENAME main" \
        > /etc/apt/sources.list.d/hashicorp.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends terraform \
    && rm -rf /var/lib/apt/lists/* \
    && terraform version

# Install uv for project dependency management and test commands.
USER codex
WORKDIR /home/codex
RUN curl --fail --silent --show-error --location https://astral.sh/uv/install.sh -o /tmp/uv-install.sh \
    && sh /tmp/uv-install.sh --no-modify-path \
    && rm /tmp/uv-install.sh \
    && uv --version \
    && uv python install 3.14 \
    && uv tool install --python 3.14 checkov \
    && python3.14 --version \
    && checkov --version

# Keep the standalone CLI outside CODEX_HOME: CODEX_HOME is a persistent runtime volume.
ARG CODEX_INSTALL_CACHE_BUST=0
# Remote control's managed app-server requires the standalone Codex installation.
USER codex
WORKDIR /home/codex
RUN printf "Codex installation cache bust: %s\n" "$CODEX_INSTALL_CACHE_BUST" \
    && curl --fail --silent --show-error --location "$CODEX_INSTALL_URL" -o /tmp/codex-install.sh \
    && CODEX_HOME=/home/codex/.local/share/codex sh /tmp/codex-install.sh \
    && rm /tmp/codex-install.sh \
    && codex --version

# Prevent Zsh’s interactive first-run configuration wizard.
RUN touch "$HOME/.zshrc"

USER root
COPY --from=codex-skills . /opt/codex-skills/
RUN find /opt/codex-skills -type f -name .DS_Store -exec rm -f {} + && find /opt/codex-skills -type d -name __pycache__ -prune -exec rm -rf {} +
RUN chown -R codex:codex /opt/codex-skills
COPY container/seed-host-config /usr/local/bin/seed-host-config
COPY container/entrypoint /usr/local/bin/entrypoint
RUN chmod 0755 /usr/local/bin/seed-host-config /usr/local/bin/entrypoint

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/entrypoint"]
CMD ["sleep", "infinity"]
