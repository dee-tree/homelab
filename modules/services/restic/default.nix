# home-manager service
{cfg, ...}: {
  lib,
  pkgs,
  ...
}: let
  scfg = cfg.services.restic;
  isExporterEnabled = scfg:
    (scfg.enable or false)
    && (scfg.backup.exporter.enable or false)
    && !(scfg.backup.exporter.disableWithReason or false);
  exporters = lib.filterAttrs (_: isExporterEnabled) cfg.services;
  repos = lib.filterAttrs (_: rcfg: (rcfg.enable or false)) scfg.repositories;
in {
  services.restic.backups =
    lib.mapAttrs (repo: rcfg: {
      raepository = rcfg.repository;
      initialize = true; # create repo if it does not exist
      passwordFile = rcfg.passwordFile;
      environmentFile = rcfg.environmentFile;
      paths = map (service: "/var/lib/backup-export/${service}/current") exporters;
      backupPrepareCommand = lib.concatMapStringsSep "\n" (exporter: "/run/current-system/sw/bin/systemctl start backup-export-${exporter}.service"); # TODO: why that path?
      extraBackupArguments =
        [
          ("--host" cfg.hostname)
          ("--retry-lock" "5m")
          ("--tag" "homelab")
        ]
        ++ lib.concatMap
        (service: ["--tag" "service:${service}"])
        exporters;
      pruneOpts = [
        "--keep-hourly 6"
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 12"
        "--keep-yearly 5"
      ];

      timerConfig = {
        OnCalendar = rcfg.schedule;
        Persistent = true;
        RandomizedDelaySec = "10m";
      };
    })
    repos;
}
