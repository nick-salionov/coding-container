FROM debian:13.6-slim

ARG CODEX_INSTALL_URL=https://chatgpt.com/codex/install.sh

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
        gosu \
        openssh-client \
        procps \
        tmux \
        zsh \
    && rm -rf /var/lib/apt/lists/* \
    && groupadd --gid 1000 codex \
    && useradd --uid 1000 --gid codex --create-home --shell /usr/bin/zsh codex

# Remote control's managed app-server requires the standalone Codex installation.
USER codex
WORKDIR /home/codex
RUN curl --fail --silent --show-error --location "$CODEX_INSTALL_URL" -o /tmp/codex-install.sh \
    && sh /tmp/codex-install.sh \
    && rm /tmp/codex-install.sh \
    && "$CODEX_HOME/packages/standalone/current/codex" --version

# Prevent Zsh’s interactive first-run configuration wizard.
RUN touch "$HOME/.zshrc"

USER root
COPY --from=codex-skills . /opt/codex-skills/
RUN find /opt/codex-skills -type f -name .DS_Store -exec rm -f {} + && find /opt/codex-skills -type d -name __pycache__ -prune -exec rm -rf {} +
RUN chown -R codex:codex /opt/codex-skills
COPY docker/seed-host-config /usr/local/bin/seed-host-config
COPY docker/entrypoint /usr/local/bin/entrypoint
RUN chmod 0755 /usr/local/bin/seed-host-config /usr/local/bin/entrypoint

WORKDIR /workspace
ENTRYPOINT ["/usr/local/bin/entrypoint"]
CMD ["sleep", "infinity"]
