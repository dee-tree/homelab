# Restic

Restic is a backup system.

## Setup

1. Generate password for clients authentication reasons for each client with:
   1. `htpasswd -B -c ${BACKUP_WITH_RESTIC_PATH_1}/.htpasswd <clientname>`. Generated `.htpasswd` file should be located inside persistent `/data` directory with the repo files on its top-level. For adding extra users use the same command omitting `-c` option.
2. Reverse proxy configuration is in [nginx file](/nginx/config/conf.d/restic.mydomain.com.conf)

## Run

Being in *restic* directory, run:
`docker compose --env-file ./config/.secrets.env -f docker-compose.yml up -d`

## How does it correspond with services?

### Why restic in docker?

> Restic REST server works in docker container as a backend for backups. Multiple destinations (services within single/multiple machines) back up to it.

### How do services backup to restic?

> There is a globally available `restic` instance available on the machine where services run.  
   Each service that going to have backups should provide its own `systemd` service & timer for backup job with the `restic backup` command executable from there. Currently, all these services must be written manually (even their schedule) without any templating that really sucks, but it is an issue for the future job.


### Replication

#### local-to-local ("1-to-2")

> Restic backups data on backend (server) is periodically replicated to local restic repo (with systemd timer, right) as "1-to-2" backup.

#### local-to-cloud ("1-to-cloud")

> The same replication process stands for replication to cloud.
