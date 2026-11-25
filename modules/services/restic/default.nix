# home-manager service
{
  config,
  hostConfig,
  lib,
  pkgs,
  ...
}: let
  scfg = hostConfig.services.restic;
  isExporterEnabled = scfg:
    (scfg.enable or false)
    && (scfg.backup.exporter.enable or false)
    && (scfg.backup.exporter.disableWithReason == null);
  exporters = lib.filterAttrs (_: isExporterEnabled) hostConfig.services;
  repos = lib.filterAttrs (_: rcfg: (rcfg.enable or false)) scfg.repositories;
in {
  assertions = [
    {
      assertion = (builtins.attrNames exporters) != [] || (scfg.enable or false);
      message = "At least one service should enable its exporter or 'services.restic' should be disabled";
    }
    {
      assertion = (builtins.attrNames repos) != [] || (scfg.enable or false);
      message = "At least one target repository should be enabled or 'services.restic' should be disabled";
    }
  ];
  imports = [ (import ./restore.nix {
    inherit config;
    cfg = hostConfig;
  }) ];
  services.restic.enable = scfg.enable;
  # TODO: implement secondary dump-copy backups
  services.restic.backups =
    lib.mapAttrs (repo: rcfg: {
      repository = rcfg.repository;
      initialize = true; # create repo if it does not exist
      passwordFile = rcfg.passwordFile;
      environmentFile = rcfg.envFile;
      paths = lib.mapAttrsToList (_: scfg: "${scfg.backup.exporter.exportRelativePath}/current") exporters;
      backupPrepareCommand = lib.concatMapStringsSep "\n" (exporter: "/usr/bin/sudo -n ${pkgs.systemd}/bin/systemctl start backup-export-${exporter}.service") (builtins.attrNames exporters);
      extraBackupArgs =
        [
          "--host" hostConfig.hostname
          "--retry-lock" "5m"
          "--tag" "homelab"
        ]
        ++ lib.concatMap
        (service: ["--tag" "service:${service}"])
        (builtins.attrNames exporters);

      extraOptions = rcfg.extraOptions;

      pruneOpts = [
        "--keep-hourly 6"
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 12"
        "--keep-yearly 5"
      ];

      timerConfig =
        if rcfg.schedule == null
        then null
        else {
          OnCalendar = rcfg.schedule;
          Persistent = true;
          RandomizedDelaySec = "10m";
        };
    })
    repos;

    systemd.user.services = lib.mapAttrs'
      (repo: _: lib.nameValuePair "restic-backups-${repo}" {
        Service.WorkingDirectory = scfg.exportRoot;
      })
      repos;
}
