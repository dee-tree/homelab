{
  hostConfig,
  scfg,
  lib,
  pkgs,
  ...
}: let
  nginxConf = pkgs.writeText "nginx.conf" (import ./config/nginx.conf.nix {
    inherit lib;
    cfg = hostConfig;
  });
in {
  main = {
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
    extraConfig = {
      Container.HealthCmd = "curl -fsS http://127.0.0.1:80/ || exit 1";
    };
  };
}
