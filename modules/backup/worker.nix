{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab;
  mkServiceUser = import ../workers/mk-service-user.nix;

  homeModule = {config, ...}: {
    imports = map (service: ../services/${service}) [ "restic" ];

    home.packages = with pkgs; [
      restic
    ];
    sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
  };

  user = mkServiceUser {
    inherit (cfg) enable;
    user = cfg.users.homelab-backup.name;
    uid = cfg.users.homelab-backup.id;
    subIdStart = cfg.users.homelab-backup.subIdStart;
    inherit homeModule;
  };
in {
  imports = [user ./backup-reader-group.nix];
}
