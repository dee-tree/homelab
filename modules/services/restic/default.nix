{name}: {config, scfg, ...}: let
  mkService = import ../../../lib/mk-service.nix;

  service = mkService {
    inherit name;
    home = {
      hostConfig,
      lib,
      pkgs,
      ...
    }: {
      imports = [ ./backup.nix ./restore.nix ];
    };
  };
in {
  imports = [service];
}
