# home-manager service
{cfg, ...}: {
  lib,
  pkgs,
  ...
}:
# arguments are supplied by home-manager
let
scfg = cfg.services.crowdsec;
  acquisition = pkgs.writeText "acquis.yaml" (import ./config/acquis.yaml.nix { inherit lib cfg; });
in {
  services.podman = {
    enable = true;

    containers.crowdsec = lib.mkIf scfg.enable {
      image = "${scfg.image}:${scfg.label}";
      ports = [
        "127.0.0.1:50120:8080"
      ];
      volumes = [
        "${acquisition}:/etc/crowdsec/acquis.yaml:ro"
        "/var/lib/crowdsec/config:/etc/crowdsec:rw"
        "/var/lib/crowdsec/data:/var/lib/crowdsec/data:rw"
        "/var/log:/var/log:ro" # traefik and system logs for access analysis
      ];
      network = [
        "revproxy.network"
      ];
      environment = {
        COLLECTIONS = "crowdsecurity/traefik crowdsecurity/http-cve crowdsecurity/whitelist-good-actors crowdsecurity/iptables crowdsecurity/linux crowdsecurity/sshd crowdsecurity/appsec-virtual-patching crowdsecurity/appsec-generic-rules";
      };
      labels = {
      };
      ip4 = scfg.ip4;
      autoStart = true;
      extraConfig = {
        Container.GroupAdd = "keep-groups"; # preserve adm group for syslogs access
        Container.HealthCmd = "cscli lapi status";
        Container.ContainerName = "crowdsec";
        Container.HealthInterval = "30s";
        Container.HealthTimeout = "5s";
        Container.HealthRetries = 3;
        Container.HealthOnFailure = "kill";

        Service = {
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
    };
  };
}
