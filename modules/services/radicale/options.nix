{
  config,
  cfg,
  scfg,
  lib,
  ...
}: let
  inherit (lib) mkOption types;
  home = config.users.users.${cfg.users.${scfg.runtimeUser}.name}.home;
in {
  usersFile = mkOption {
    type = types.nullOr types.str;
    default = null;

    description = ''
      Host-side runtime file containing the users auth data.
    '';
  };

  dataDir = mkOption {
    type = types.path;
    default = "${home}/data/radicale";
    description = "Path to persistent data on the host";
  };
}
