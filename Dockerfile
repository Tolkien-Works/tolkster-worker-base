# A worker machine's base: Ubuntu LTS with Node 24, git and Orca's Linux app, for a machine
# that pairs through `orca-ide serve`. Software only: nothing in it is signed in, and it holds
# no credential, Orca profile or project.
#
# Claude Code isn't in it: its terms don't allow redistributing it. A machine installs it as
# it starts, with the native installer, which needs no root and puts `claude` in
# ~/.local/bin (already on PATH here):
#   curl -fsSL https://claude.ai/install.sh | bash
FROM ubuntu:26.04

LABEL org.opencontainers.image.source=https://github.com/Tolkien-Works/tolkster-worker-base
LABEL org.opencontainers.image.description="Orca's Linux app and git on Ubuntu, signed in to nothing"

ENV DEBIAN_FRONTEND=noninteractive

# Git from the Ubuntu Git Maintainers' PPA: hooks run from config (`git hook list`) need Git
# 2.54, newer than any LTS archive's. Its signing key is kept here, checked against the
# fingerprint Launchpad publishes (F911AB184317630C59970973E363C90F8F1B6217), not fetched.
# The PPA is HTTPS, which apt skips with only a warning until ca-certificates is in.
COPY git-core-ppa.asc /etc/apt/keyrings/git-core-ppa.asc
RUN apt-get update \
  && apt-get install -y --no-install-recommends ca-certificates \
  && printf 'Types: deb\nURIs: https://ppa.launchpadcontent.net/git-core/ppa/ubuntu\nSuites: resolute\nComponents: main\nSigned-By: /etc/apt/keyrings/git-core-ppa.asc\n' \
    > /etc/apt/sources.list.d/git-core-ppa.sources \
  && rm -rf /var/lib/apt/lists/*

# Node 24's latest release from nodejs.org, checked against its SHASUMS256. The nightly
# workflow passes Orca's latest release; apt pulls the Electron libraries its .deb declares,
# and libgbm1 and libasound2t64, which it needs without declaring.
ARG ORCA_VERSION
RUN test -n "$ORCA_VERSION" \
  && apt-get update \
  && apt-get install -y --no-install-recommends curl xz-utils git procps libgbm1 libasound2t64 \
  && cd /tmp \
  && curl -fsSLO https://nodejs.org/dist/latest-v24.x/SHASUMS256.txt \
  && node=$(grep -o 'node-v24[^ ]*-linux-x64\.tar\.xz' SHASUMS256.txt) \
  && curl -fsSLO "https://nodejs.org/dist/latest-v24.x/$node" \
  && grep " $node\$" SHASUMS256.txt | sha256sum -c - \
  && tar -xJf "$node" -C /usr/local --strip-components=1 --exclude='*.md' --exclude=LICENSE \
  && curl -fsSL -o /tmp/orca.deb \
    "https://github.com/stablyai/orca/releases/download/v${ORCA_VERSION}/orca-ide_${ORCA_VERSION}_amd64.deb" \
  && apt-get install -y --no-install-recommends /tmp/orca.deb \
  && rm -rf /var/lib/apt/lists/* /tmp/* \
  && node --version \
  && orca-ide --version \
  && git --version

# The `node` user (uid 1000) runs everything; what it installs lands in its home. Ubuntu's
# image gives uid 1000 to `ubuntu`, so that user makes way.
RUN userdel --remove ubuntu \
  && useradd --create-home --uid 1000 --shell /bin/bash node
ENV PATH=/home/node/.local/bin:${PATH}
USER node
WORKDIR /home/node
