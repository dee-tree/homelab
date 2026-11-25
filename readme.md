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

## Backups

Backups are set declarative too including restoration.
Currently, restic is used for backing-up with declarative repositories.

### How does it work?

At the host, a specialuser manages backups and owns `restic`.

1. Publicly facing restic user systemd service (`restic-backups-<restic-repo-name>.service`, owned by restic) starts backup process (by timer / manually triggered) of all back-up-able services at once.
2. At `backupPrepareCommand` of restic service, export of services persistent data is triggered via `backup-export-<service-name>.service` service run.
3. Each back-up-able service exposes its own user systemd service `backup-export-<servie-name>.service` that dumps its data to the export staging directory (`restic.exportRoot/<service>.backup.exporter.relativePath`). To preserve data consistency, each service could declare its stop/start commands via `<service>.backup.exporter.preCommand/postCommand`
4. `restic-backups-<restic-repo-name>.service` runs restic on export staging directory.

To check exporting to staging logs: `sudo journalctl -e -u backup-export-<service>.service`
To check restic backup process logs itself: `sudo journalctl -t restic -e`

### Trigger backup

To trigger backup, start:
```sh
sudo systemctl --user --machine=homelab-backup@.host start restic-backups-<restic-repo-name>.service
```
Backups are triggered for all services at once within 1 snapshot.

### Backup restoration

Similarly with backing-up, restoration consists of 2 parts: 
1. Staging restic snapshot data of the service to the `restic.restore.stagingRoot/<service-name>` with `backup-restore` / `backup-restore-command` of the restic user.
2. Triggering backup restoration from the staging directory to the service `sources` paths with system systemd service `backup-restore-<service-name>.service`. Before, it checks if staging already exists. To preserve data consistency, each service could declare its stop/start commands via `<service>.backup.exporter.preCommand/postCommand`.
3. Original service `sources` are preserved in `restic.restore.rollbackRoot/<service-name>` and not deleted automatically. Consider clean rollbackRoot directory manually on space run-out.

Usage:
```sh
AS_USER=homelab-backup task inspect -- backup-restore <service-name> <restic-repo-name> <snapshot-id>
sudo systemctl start backup-restore-<service-name>.service
```

To check restoration log, read: `sudo journalctl -e -u backup-restore-<service-name>`.

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
