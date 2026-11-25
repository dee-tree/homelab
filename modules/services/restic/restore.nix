# home-manager module
{ config, cfg, ... }:
{ lib, pkgs, ... }:

let
  scfg = cfg.services.restic;
  q = lib.escapeShellArg;

  repositoryCases = lib.concatStringsSep "\n" (
    lib.mapAttrsToList
      (name: repo: ''
        ${q name})
          resticArgs=(
            --repo ${q repo.repository}
            --password-file ${q repo.passwordFile}
          )
          ;;
      '')
      scfg.repositories
  );

  serviceCases = lib.concatStringsSep "\n" (
    lib.mapAttrsToList
      (name: scfg: ''
        ${q name})
          exportPath=${q "/${scfg.backup.exporter.exportRelativePath}/current"}
          snapshotHost=${q cfg.hostname}
          snapshotTag=${q "service:${name}"}
          destination=${q "${cfg.services.restic.restore.stagingRoot}/${name}"}
          sourcesJson=${q (
            builtins.toJSON (map toString scfg.backup.exporter.sources)
          )}
          ;;
      '')
      cfg.services
  );

  restore = pkgs.writeShellScript "backup-restore" ''
    set -euo pipefail
    umask 077

    export PATH=${lib.makeBinPath [
      pkgs.coreutils
      pkgs.jq
      pkgs.util-linux
    ]}

    if [[ $# -ne 3 ]]; then
      echo "Usage: backup-restore SERVICE REPOSITORY SNAPSHOT_ID" >&2
      exit 2
    fi

    if [[ $(${pkgs.coreutils}/bin/id -un) != ${q cfg.users.homelab-backup.name} ]]; then
      echo "Run this command as ${cfg.users.homelab-backup.name}." >&2
      exit 1
    fi

    service=$1
    repository=$2
    snapshot=$3

    case "$service" in
      ${serviceCases}
      *)
        echo "Unknown service: $service" >&2
        exit 2
        ;;
    esac

    case "$repository" in
      ${repositoryCases}
      *)
        echo "Unknown repository: $repository" >&2
        exit 2
        ;;
    esac

    if [[ ! "$snapshot" =~ ^[[:xdigit:]]{8,64}$ ]]; then
      echo "Invalid snapshot format: provide hexadecimal snapshot ID." >&2
      exit 2
    fi

    ${pkgs.coreutils}/bin/mkdir -p -- ${q scfg.restore.stagingRoot}

    # Serialize staging operations for this service.
    exec 9>"$destination.stage.lock"
    flock -n 9 || {
      echo "A staging operation is already running. stage.lock file exists" >&2
      exit 1
    }

    if [[ -e "$destination" || -L "$destination" ]]; then
      echo "A recovery is already staged at $destination" >&2
      echo "Move or remove it explicitly before staging another." >&2
      exit 1
    fi

    # Do not inherit another job's Restic password/repository settings.
    while IFS= read -r variable; do
      unset "$variable"
    done < <(compgen -v RESTIC_)

    restic() {
      ${pkgs.restic}/bin/restic "''${resticArgs[@]}" "$@"
    }

    snapshotId=$(
      restic snapshots --json "$snapshot" |
        jq -er \
          --arg host "$snapshotHost" \
          --arg tag "$snapshotTag" '
            if length != 1 then
              error("Expected exactly one snapshot")
            elif .[0].hostname != $host then
              error("Snapshot host mismatch")
            elif ((.[0].tags // []) | index($tag)) == null then
              error("Snapshot service tag mismatch")
            else
              .[0].id
            end
          '
    )

    temporary=$(mktemp -d "$destination.partial.XXXXXXXX")
    trap 'rm -rf -- "$temporary"' EXIT

    restic restore "$snapshotId:$exportPath" \
      --target "$temporary/payload" \
      --verify

    test -d "$temporary/payload"

    jq -n \
      --arg service "$service" \
      --arg repository "$repository" \
      --arg snapshot "$snapshotId" \
      '{
        service: $service,
        repository: $repository,
        snapshot: $snapshot,
        complete: true
      }' > "$temporary/manifest.json"

    mv -- "$temporary" "$destination"
    trap - EXIT

    printf 'Verified recovery staged at %s\n' "$destination"
    printf 'Snapshot: %s\n' "$snapshotId"
    printf 'Live data has not been changed.\n'
  '';
in
{
  home.packages = [
    (pkgs.runCommand "backup-restore-command" { } ''
      mkdir -p "$out/bin"
      ln -s ${restore} "$out/bin/backup-restore"
    '')
  ];
}
