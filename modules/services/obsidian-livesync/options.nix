{config, cfg, scfg, lib, ...}: let
  inherit (lib) mkOption types;
  home = config.users.users.${cfg.users.${scfg.runtimeUser}.name}.home;

in {
  dataDir = mkOption {
    type = types.path;
    default = "${home}/data/obsidian";
    description = "Path to persistent data on the host";
  };
}
