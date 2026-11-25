{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  users = config.homelab.users;
  userDirs = lib.attrNames (lib.filterAttrs (n: t: t == "directory") (builtins.readDir ./users));
  mkServiceUser = import ./mk-service-user.nix;
  mkuser = user: let
    ucfg = users.${user};
  in
    mkServiceUser {
      user = ucfg.name;
      uid = ucfg.id;
      subIdStart = ucfg.subIdStart;
      homeModule = ./users/${user}/home.nix;
    };
in {
  imports =
    (map (user: ./users/${user}/system.nix) userDirs)
    ++ (map mkuser userDirs);
}
