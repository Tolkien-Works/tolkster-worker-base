# tolkster-worker-base

The base image for a machine that runs coding agents through [Orca](https://github.com/stablyai/orca)'s
remote runtimes: Ubuntu 26.04 LTS with Node 24, git that runs hooks from config (2.54 or
later, from the Ubuntu Git Maintainers' PPA) and Orca's Linux app (`orca-ide serve`).

```
docker pull ghcr.io/tolkien-works/tolkster-worker-base:latest
```

- **Software only.** Nothing in it is signed in: no Claude login, Git or GitHub credential,
  Orca profile or project. Those reach a machine after it starts, from whatever enrols it.
- **No Claude Code.** Its terms don't allow redistributing it, so a machine installs it as it
  starts, without root, into `~/.local/bin`, which is on PATH:
  `curl -fsSL https://claude.ai/install.sh | bash`.
- **Rebuilt on Orca's releases.** A nightly workflow builds and pushes only when Orca has
  released a version the image lacks, tagged `orca-<version>` and `latest`.
- Build your project's toolchains and caches as a layer on top of it.

Orca is MIT licensed; its `.deb` carries its licence.
