# Homelab 2.0

<p align="center">
  <img src="./assets/logo-square.png" alt="Homelab - logo" width="128">
</p>

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

## Logo attribution

The Homelab logo adapts the [NixOS Logo](https://github.com/NixOS/branding)
by Simon Frankau, Tim Cuthbertson, and Daniel Baker, maintained by the
NixOS Marketing Team and licensed under
[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
The snowflake was recolored and a house made from two mirrored lambdas
with a four-pane window was added.
