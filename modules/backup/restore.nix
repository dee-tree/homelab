# system-manager module
{ config, lib, pkgs, ... }:

let
  cfg = config.homelab;
  q = lib.escapeShellArg;

  hasPersistentData = scfg: scfg.backup.exporter.sources != [];
  # Make restorable only the services with declared sources for backup
  services = lib.filterAttrs (_: hasPersistentData) cfg.services;

  mkRestore = name: scfg:
    let
      stage = "${cfg.backup.restore.stagingRoot}/${name}";
      b = scfg.backup.exporter;

      preCommand = scfg.backup.exporter.preCommand or "";
      postCommand = scfg.backup.exporter.postCommand or "";

      pre = pkgs.writeShellScript "backup-restore-${name}-pre" ''
        set -euo pipefail
        ${preCommand}
      '';

      post = pkgs.writeShellScript "backup-restore-${name}-post" ''
        set -euo pipefail
        ${postCommand}
      '';

      apply = pkgs.writeShellScript "backup-restore-${name}" ''
        set -Eeuo pipefail
        umask 077

        reportError() {
            local status=$1
            local line=$2
            local command=$3

            printf 'Restore error: exit=%s line=%s command=%s\n' \
            "$status" "$line" "$command" >&2
        }

        trap 'reportError "$?" "$LINENO" "$BASH_COMMAND"' ERR
        umask 077

        abort() {
            printf 'Restore failed: %s\n' "$*" >&2
            exit 1
        }

        export PATH=${lib.makeBinPath [
          pkgs.coreutils
          pkgs.findutils
          pkgs.jq
          pkgs.util-linux
        ]}

        if (( EUID != 0 )); then
          printf '%s\n' \
            "Restore apply must run as root; invoke it with sudo." >&2
          exit 1
        fi

        sources=( ${lib.escapeShellArgs (map toString b.sources)} )
        stage=${q stage}

        # All privileged exporter/restore operations use this lock.
        mkdir -p /run/homelab-backup-locks
        chmod 0700 /run/homelab-backup-locks

        exec 8>${q "/run/homelab-backup-locks/${name}.lock"}
        flock -x 8

        # Serialize with Home Manager's staging operation.
        exec 9<>${q "${cfg.backup.restore.stagingRoot}/${name}.lock"}
        flock -x 9

        [[ -d "$stage" && ! -L "$stage" ]] ||
          abort "Missing or invalid staging directory: $stage"

        [[ -d "$stage/payload" && ! -L "$stage/payload" ]] ||
          abort "Missing or invalid payload directory: $stage/payload"

        [[ -f "$stage/manifest.json" && ! -L "$stage/manifest.json" ]] ||
          abort "Missing or invalid manifest: $stage/manifest.json"

        jq -e \
          --arg service ${q name} \
          '.complete == true and .service == $service' \
          "$stage/manifest.json" >/dev/null

          candidates=()
          rollbacks=()

          hooksStarted=false
          safeToRestart=true
          installationStarted=false
          successful=false

        finish() {
            status=$?
            trap - EXIT ERR
            set +e

            # Restart after preparation/pre-hook failures, but never
            # automatically start against a partial installation.
            if [[ "$hooksStarted" == true && "$safeToRestart" == true ]]; then
                ${post}
                postStatus=$?
                if [[ "$postStatus" -ne 0 ]]; then
                status=$postStatus
                fi
            fi

            for candidate in "''${candidates[@]}"; do
                if [[ -d "$candidate" ]]; then
                rm -rf -- "$candidate"
                fi
            done

            if [[ "$successful" != true ]]; then
                echo "Recovery failed for ${name}." >&2

                if [[ "$installationStarted" == true ]]; then
                echo "Inspect live and rollback directories before restarting." >&2
                printf 'Rollback location: %s\n' \
                    "''${rollbacks[@]}" >&2
                fi
            fi

            exit "$status"
        }
        trap finish EXIT

        stamp="$(date -u +%Y%m%dT%H%M%S).$$"

        # Restore
        for live in "''${sources[@]}"; do
            [[ "$live" == /* && "$live" != / ]]
            [[ "$live" != */ ]]
            test -d "$(dirname -- "$live")"
            test ! -L "$live"

            if [[ -e "$live" ]]; then
            test -d "$live"
            fi

            if mountpoint -q -- "$live"; then
            echo "Cannot replace a mount point: $live" >&2
            exit 1
            fi

            restored="$stage/payload/$(basename -- "$live")"

            [[ -d "$restored" && ! -L "$restored" ]] ||
              abort "Expected restored source directory is missing or invalid: $restored"

            candidate=$(mktemp -d "$live.restore.XXXXXXXX")
            candidates+=("$candidate")

            rollback="$live.rollback.$stamp"
            test ! -e "$rollback"
            test ! -L "$rollback"
            rollbacks+=("$rollback")

            # Copy links as links, then reject unsupported file types.
            cp -a -- "$restored/." "$candidate/"

            unsupported=$(
            find "$candidate" \
                ! -type d ! -type f \
                -print -quit
            )

            if [[ -n "$unsupported" ]]; then
            echo "Unsupported restored file: $unsupported" >&2
            exit 1
            fi

            # Break hard links before assigning live ownership, so no
            # candidate shares file inodes with untrusted staging.
            #
            # cp -a already creates a separate copy from staging;
            # internal hard links within the candidate are acceptable.

            chown -R -- ${q "${cfg.users.worker.name}:${cfg.users.worker.name}"} "$candidate"
            find "$candidate" -type d -exec chmod 0700 {} +
            find "$candidate" -type f -exec chmod 0600 {} +
        done

        hooksStarted=true
        ${pre}

        # From this point until all renames complete, a failure must
        # leave the application stopped.
        safeToRestart=false
        installationStarted=true

        for i in "''${!sources[@]}"; do
            live="''${sources[$i]}"
            candidate="''${candidates[$i]}"
            rollback="''${rollbacks[$i]}"

            if [[ -e "$live" ]]; then
            mv -T -- "$live" "$rollback"
            fi

            mv -T -- "$candidate" "$live"
        done

        # Run the post hook explicitly so a failed start is reported
        # as a failed systemd invocation, without retrying it in EXIT.
        hooksStarted=false
        ${post}
        successful=true

        printf 'Recovery installed for %s\n' "${name}"
        printf 'Previous data retained at %s\n' "$rollback"
        printf 'Staging recovery retained at %s\n' "$stage"
      '';
    in
    lib.nameValuePair "backup-restore-${name}" {
      description = "Apply staged restore for ${name}";

      serviceConfig = {
        Type = "oneshot";
        User = "root";
        ExecStart = apply;

        # Large restores can take longer than the normal start timeout.
        TimeoutStartSec = "infinity";
        UMask = "0077";
        # No timer, only manual execution
      };
    };
in
{
  systemd.services = lib.mapAttrs' mkRestore services;
}
