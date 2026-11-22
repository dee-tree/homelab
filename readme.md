# Homelab 2.0

Homelab that on its duty.

- Configurable and customizable
- Declarative
- Reproducible

## Usage

### Prerequisites

- Ensure `HOMELAB_SECRETS_REPO` variable is set and pointing to the `homelab.secrets` repo in nix inputs format. In the future, there will be a template flake in `./config/secrets`

TBD...

See `taskfile.yml`

## Status

The previous, legacy version contains docker-compose declarations for the services. In the future, they will be replaced with nix modules.

Currently, the following services are supported as a nix: nginx, xray, traefik, crowdsec.
