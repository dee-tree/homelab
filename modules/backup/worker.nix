{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab;
  mkServiceUser = import ../workers/mk-service-user.nix;

  homeModule = {config, ...}: let
    importService = service: (import ../services/${service} {
      inherit cfg config;
    });
  in {

    imports = map importService [ "restic" ];

    home.packages = with pkgs; [
      restic
    ];
    sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };

  user = mkServiceUser {
    inherit (cfg) enable;
    user = cfg.users.backup.name;
    uid = cfg.users.backup.id;
    subIdStart = cfg.users.backup.subIdStart;
    inherit homeModule;
  };
in {
  imports = [user ./backup-reader-group.nix];
}
