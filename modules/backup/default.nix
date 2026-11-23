{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab;
  enabledExporters = lib.filterAttrs (_: scfg: (scfg.backup.exporter.enable or false)) cfg.services;

  mkExport = service: b: let
    exportCommand =
      if b.exportCommand == null
      then ''
        for src in ${lib.escapeShellArgs (map toString b.sources)}; do
          cp -a --reflink=auto --parents -- "$src" "$EXPORT_DIR/"
        done
      ''
      else b.exportCommand;
  in
    pkgs.writeShellApplication {
      name = "export-${service}";
      runtimeInputs = with pkgs;
        [
          gnutar
          zstd
          coreutils
        ]
        ++ b.runtimeInputs;
      text = ''
        work="$STATE_DIRECTORY/.new"
        rm -rf "$work"; mkdir -p "$work"
        export EXPORT_DIR="$work"
        ${exportCommand}
        chown -R root:backup_readers "$EXPORT_DIR"
        chmod -R u=rwX,g=rX,o= "$EXPORT_DIR"
        rm -rf "$STATE_DIRECTORY/current"
        mv "$work" "$STATE_DIRECTORY/current"
      '';
    };
in {
  assertions =
    (lib.mapAttrsToList (service: scfg: {
      assertion =
        (scfg.backup.exporter.enable or false) || (scfg.backup.exporter.disableWithReason or null) != null;
      message = "${service} service has neither `backup.exporter.enable` nor `backup.exporter.disableWithReason` specified";
    }) (lib.filterAttrs (_: scfg: (scfg.enable or false)) cfg.services)) # TODO: add persistentPaths to filter
    ++ (lib.mapAttrsToList (service: scfg: {
        assertion = scfg.backup.exporter.exportCommand != null || scfg.backup.exporter.sources != [];
        message = "${service} service should set either `backup.exporter.exportCommand` or `backup.exporter.sourcePaths`";
      })
      enabledExporters);

  # # Bridge for passing hostConfig into home-manager module
  # _module.args.hostConfig = config.homelab;

  imports = [./backup-reader-group.nix ./worker.nix];

  environment.etc."sudoers.d/backup-export" = {
    mode = "0440";
    # TODO: replace '*' with explicit exorters list
    text = ''
      backup ALL=(root) NOPASSWD: /usr/bin/systemctl start backup-export-*.service
    '';
  };

  systemd.services =
    lib.mapAttrs' (
      service: scfg: let
        b = scfg.backup.exporter;
      in
        lib.nameValuePair "backup-export-${service}" {
          serviceConfig = {
            Type = "oneshot";
            Group = "backup-readers";
            UMask = "0027";
            StateDirectory = "backup-export/${service}"; # resolved into /var/lib/backup-export for system service
            StateDirectoryMode = "0750";
            ExecStartPre = lib.optional (b.preCommand != null) b.preCommand;
            ExecStart = "${mkExport service b}/bin/export-${service}";
            ExecStopPost = lib.optional (b.postCommand != null) b.postCommand;
          };
        }
    )
    enabledExporters;

  systemd.tmpfiles.rules = [
    "d /tmp/homelab/restic/dummy 0700 backup backup - -"
  ];
}
