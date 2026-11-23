{ lib }:
let
  inherit (lib) mkOption types mkEnableOption;

  repo = types.submodule ({ reponame, ... }: {
    options = {
      enable = mkEnableOption "Should '${reponame}' repository destination be enabled";
      repository = mkOption {
        type = types.str;
        description = "Restic repository in restic scheme; example: 'sftp:backup@host:/backups'";
      };
      passwordFile = mkOption {
        type = types.nullOr types.str;
        description = ''
          Host-side runtime file containing the restic repository password.
        '';
      };
      envFile = mkOption {
        type = types.nullOr types.str;
        description = ''
          Host-side runtime file containing the restic environment.
        '';
      };
      schedule = mkOption {
        type = types.str;
        default = "*-*-* 03:00:00";
        description = "systemd OnCalendar value";
      };
    };
  });
in
{
  repositories = mkOption {
    default = { };
    type = types.attrOf repo;
  };

}
