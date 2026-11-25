# home-manager service
{
  hostConfig,
  lib,
  pkgs,
  ...
}:
# arguments are supplied by home-manager
let
  scfg = hostConfig.services.nginx;
  nginxConf = pkgs.writeText "nginx.conf" (import ./config/nginx.conf.nix {
    inherit lib;
    cfg = hostConfig;
  });
in {
  services.podman = {
    enable = true;

    networks.revproxy = {
      driver = "bridge";
      subnet = "10.90.0.0/24";
      gateway = "10.90.0.1";
    };

    containers.nginx = lib.mkIf scfg.enable {
      image = "${scfg.image}:${scfg.label}";
      # NOTE:
      # If nginx exposes port 80 or 443, it could be required to execute at the host:
      # `sudo sysctl --system`
      #
      # ports = ["127.0.0.1:${toString scfg.httpPort}:80" "127.0.0.1:${toString scfg.httpsPort}:443"];
      ports = ["${toString scfg.httpPort}:80" "${toString scfg.httpsPort}:443"];
      volumes = [
        "${nginxConf}:/etc/nginx/nginx.conf:ro"
        "/var/log/nginx:/var/log/nginx"
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
