# home-manager service
{
  cfg,
  ...
}: {
  lib,
  pkgs,
  ...
}:
# arguments are supplied by home-manager
let
scfg = cfg.services.xray;
  xrayConf = pkgs.writeText "xray.config.json" (import ./config/config.json.nix {inherit lib cfg;});
in {
  services.podman = {
    enable = true;

    containers.xray = lib.mkIf scfg.enable {
      image = "${scfg.image}:${scfg.label}";
      volumes = [
        "${xrayConf}:/etc/xray/config.json:ro"
        "/var/log/xray:/var/log/xray"
      ];
      network = [
        "revproxy.network"
      ];
      ip4 = scfg.ip4;
      autoStart = true;
      extraConfig = {
        Service = {
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
    };
  };
}
