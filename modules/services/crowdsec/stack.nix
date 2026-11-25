{
  lib,
  pkgs,
  ...
}:
let
  acquisition = pkgs.writeText "acquis.yaml" (import ./config/acquis.yaml.nix {inherit lib;});
in {
  main = {
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
    extraConfig = {
      Container.GroupAdd = "keep-groups"; # preserve adm group for syslogs access
      Container.HealthCmd = "cscli lapi status";
    };
  };
}
