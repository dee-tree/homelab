{
  hostConfig,
  scfg,
  lib,
  pkgs,
  ...
}: let
  radicaleConfig = pkgs.writeText "radicale-config" (import ./config/config.nix {
    inherit hostConfig lib;
  });
in {
  main = {
    # Run as root inside rootless container, mapping to worker on the host
    user = "0:0";
    volumes = [
      "${radicaleConfig}:/etc/radicale/config:ro"
      "${scfg.usersFile}:/etc/radicale/users:ro"
      "${scfg.dataDir}:/var/lib/radicale"
      "/var/log/radicale:/var/log/radicale"
    ];
    labels = {
      "traefik.enable" = "true";
      "traefik.http.routers.radicale.rule" = "Host(`${scfg.subdomain}.${hostConfig.domain}`)";
      "traefik.docker.network" = "revproxy";
      "traefik.http.routers.radicale.service" = "radicale";
      "traefik.http.services.radicale.loadbalancer.server.port" = "80";
      "traefik.http.routers.radicale.entrypoints" = "websec-exposed";
      "traefik.http.routers.radicale.tls" = "true";
      "traefik.http.routers.radicale.tls.certresolver" = "production";
    };
    network = [
      "revproxy.network"
    ];
    extraConfig = {
      Container = {
        Exec = "--config /etc/radicale/config";
      };
      Container.HealthCmd = "curl --fail --silent --show-error --max-time 3 http://127.0.0.1:80/ > /dev/null";
      Unit = {
        Requires = ["sops-nix.service"];
        After = ["sops-nix.service"];
      };
    };
  };
}
