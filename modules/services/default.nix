{lib, ...}: let
  services = lib.attrNames (lib.filterAttrs (name: type: type == "directory") (builtins.readDir ./.));
in {
  imports = map (name: import (./${name}) {inherit name;}) services;
}
