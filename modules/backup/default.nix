{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab;
  enabledExporters = lib.filterAttrs (_: scfg: (scfg.backup.exporter.enable or false)) cfg.services;

  mkExport = service: b: let
  stagingDir = "${cfg.services.restic.exportRoot}/${b.exportRelativePath}";
    exportCommand =
      if b.exportCommand == null
      then ''
        sources=( ${lib.escapeShellArgs (map toString b.sources)} )
        for src in "''${sources[@]}"; do
          cp -a --reflink=auto -- "$src" "$EXPORT_DIR/"
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
        exportRoot=${lib.escapeShellArg stagingDir}
        mkdir -p -- "$exportRoot"
        work="$exportRoot/.new"
        rm -rf "$work"; mkdir -p "$work"
        export EXPORT_DIR="$work"
        ${exportCommand}
        chown -R root:backup-readers "$EXPORT_DIR"
        chmod -R u=rwX,g=rX,o= "$EXPORT_DIR"
        rm -rf "$exportRoot/current"
        mv "$work" "$exportRoot/current"
      '';
    };
in {
  assertions =
    (lib.mapAttrsToList (service: scfg: {
      assertion = (scfg.backup.exporter.enable or false) || (scfg.backup.exporter.disableWithReason or null) != null;
      message = "${service} service has neither `backup.exporter.enable` nor `backup.exporter.disableWithReason` specified";
    }) (lib.filterAttrs (_: scfg: (scfg.enable or false)) cfg.services)) # TODO: add persistentPaths to filter
    ++ (lib.mapAttrsToList (service: scfg: {
        assertion = scfg.backup.exporter.exportCommand != null || scfg.backup.exporter.sources != [];
        message = "${service} service should set either `backup.exporter.exportCommand` or `backup.exporter.sourcePaths`";
      })
      enabledExporters)
    ++ [
      {
        assertion = (cfg.services.restic.enable or false) || (cfg.services.restic.disableWithReason or null) != null;
        message = "restic has neither `restic.enable` nor `restic.disableWithReason` specified";
      }
    ];

  imports = [./backup-reader-group.nix ./restore.nix ./worker.nix];

  security.sudo.enable = true;
  security.sudo.extraRules = [
    {
      users = ["homelab-backup"];
      runAs = "root";
      commands = map (name: {
        command = "${pkgs.systemd}/bin/systemctl start backup-export-${name}.service";
        options = ["NOPASSWD"];
      }) (builtins.attrNames enabledExporters);
    }
  ];

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
            ExecStartPre = lib.optional (b.preCommand != null) b.preCommand;
            ExecStart = "${mkExport service b}/bin/export-${service}";
            ExecStopPost = lib.optional (b.postCommand != null) b.postCommand;
          };
        }
    )
    enabledExporters;

  systemd.tmpfiles.rules = [
    "d /tmp/homelab/restic/dummy 0700 homelab-backup homelab-backup - -"
  ];
}
