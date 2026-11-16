{
  config,
  lib,
  ...
}: let
  cfg = config.homelab;
  mkServiceUser = import ./mk-service-user.nix;
  services = builtins.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../services)
  );
  importService = service: (import ../services/${service} {
    inherit cfg;
  });
  user = mkServiceUser {
    inherit (cfg) enable;
    user = cfg.user;
    uid = cfg.userId;
    subIdStart = cfg.subIdStart;
    homeModule = {
      imports = map importService services;

      xdg.configFile."containers/containers.conf.d/10-timezone.conf".text = ''
        [containers]
        tz = "${cfg.timezone}"
      '';
    };
  };
in {
  imports = [user];
}
