# home-manager service
{
  config,
  cfg,
  ...
}: {
  lib,
  pkgs,
  ...
}:
# arguments are supplied by home-manager
let
  scfg = cfg.services.radicale;
  dataDir = "${config.home.homeDirectory}/data/radicale";
  radicaleConfig = pkgs.writeText "radicale-config" (import ./config/config.nix {
    inherit lib cfg;
  });
in {
  home.activation.radicaleData = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg dataDir}
    run ${pkgs.coreutils}/bin/chmod 0700 ${lib.escapeShellArg dataDir}
  '';
  services.podman = {
    enable = true;

    containers.radicale = lib.mkIf scfg.enable {
      image = "${scfg.image}:${scfg.label}";
      # Run as root inside rootless container, mapping to worker on the host
      user = "0:0";
      volumes = [
        "${radicaleConfig}:/etc/radicale/config:ro"
        "${scfg.usersFile}:/etc/radicale/users:ro"
        "${dataDir}:/var/lib/radicale"
        "/var/log/radicale:/var/log/radicale"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.radicale.rule" = "Host(`${scfg.subdomain}.${cfg.domain}`)";
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
      ip4 = scfg.ip4;
      autoStart = true;
      extraConfig = {
        Container = {
          Exec = "--config /etc/radicale/config";
        };
        Container.HealthCmd = "curl --fail --silent --show-error --max-time 3 http://127.0.0.1:80/ > /dev/null";
        Container.HealthInterval = "30s";
        Container.HealthTimeout = "5s";
        Container.HealthRetries = 3;
        Container.HealthOnFailure = "kill";
        Service = {
          Restart = "on-failure";
          RestartSec = "5s";
        };
        Unit = {
          Requires = ["sops-nix.service"];
          After = ["sops-nix.service"];
        };
      };
    };
  };
}
