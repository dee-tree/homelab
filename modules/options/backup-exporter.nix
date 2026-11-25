{lib, ...}: let
  inherit (lib) mkOption mkEnableOption types;
in {
  exporter = service: {
    enable = mkEnableOption "Should backup exporter be enabled for the ${service} service";
    disableWithReason = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Reason why ${service} should not be backed up";
    };
    sources = mkOption {
      type = types.listOf types.path;
      description = "Paths included to the backup";
    };
    mode = mkOption {
      type = types.enum ["copy" "command"];
      default = "copy";
    };
    preCommand = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Command called before exporting a backup; could be used for graceful service stop";
    };
    postCommand = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Command called after exporting a backup; could be used for graceful service restart";
    };
    exportCommand = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Command called for exporting backup. `null` has semantics of default archive dump behavior. For custom command, place backup to `$EXPORT_PATH`";
    };
    exportRelativePath = mkOption {
      type = types.str;
      default = "services/${service}";
      description = "Path relative to config.homelab.services.restic.exportRoot to be backed up in staging";
    };
    runtimeInputs = mkOption {
      type = types.listOf types.package;
      default = [];
      description = "Packages are provided to the 'exportCommand'";
    };
  };
}
