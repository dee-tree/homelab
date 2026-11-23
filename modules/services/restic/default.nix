# home-manager service
{ cfg, ... }:
{
  lib,
  pkgs,
  ...
}:
let
scfg = cfg.services.restic;
  isExporterEnabled =
    scfg:
    (scfg.enable or false)
    && (scfg.backup.exporter.enable or false)
    && !(scfg.backup.exporter.disableWithReason or false);
  exporters = lib.filterAttrs (_: isExporterEnabled) cfg.services;
  repos = lib.filterAttrs (_: rcfg: (rcfg.enable or false)) scfg.repositories;
in
{

  services.restic.backups = lib.mapAttrs (repo: rcfg: {
    repository = rcfg.repository;
    passwordFile = rcfg.passwordFile;
    environmentFile = rcfg.environmentFile;
    initialize = ?; # TODO
    paths = map (service: "/var/lib/backup-export/${service}/current") exporters;
    backupPrepareCommand = lib.concatMapStringsSep "\n" (exporter: "/run/current-system/sw/bin/systemctl start backup-export-${exporter}.service"); # TODO: why that path?
  }) repos;
}
