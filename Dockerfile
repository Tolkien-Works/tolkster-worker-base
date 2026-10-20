# A worker machine's base: Debian with Node 24, git and Orca's Linux app, for a machine that
# pairs through `orca-ide serve`. Software only: nothing in it is signed in, and it holds no
# credential, Orca profile or project.
#
# Claude Code isn't in it: its terms don't allow redistributing it. A machine installs it as
# it starts, with the native installer, which needs no root and puts `claude` in
# ~/.local/bin (already on PATH here):
#   curl -fsSL https://claude.ai/install.sh | bash
FROM node:24-bookworm-slim

LABEL org.opencontainers.image.source=https://github.com/Tolkien-Works/tolkster-worker-base
LABEL org.opencontainers.image.description="Orca's Linux app and git on Debian, signed in to nothing"

ENV DEBIAN_FRONTEND=noninteractive

# The nightly workflow passes Orca's latest release; apt pulls the Electron libraries its
# .deb declares, and libgbm1 and libasound2, which it needs without declaring.
ARG ORCA_VERSION
RUN test -n "$ORCA_VERSION" \
  && apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates curl git procps libgbm1 libasound2 \
  && curl -fsSL -o /tmp/orca.deb \
    "https://github.com/stablyai/orca/releases/download/v${ORCA_VERSION}/orca-ide_${ORCA_VERSION}_amd64.deb" \
  && apt-get install -y --no-install-recommends /tmp/orca.deb \
  && rm -rf /var/lib/apt/lists/* /tmp/orca.deb \
  && orca-ide --version \
  && git --version

# The image's `node` user (uid 1000) runs everything; what it installs lands in its home.
ENV PATH=/home/node/.local/bin:${PATH}
USER node
WORKDIR /home/node
