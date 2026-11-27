{
  hostConfig,
  config,
  scfg,
  lib,
  pkgs,
  ...
}: let
  livesyncConfig = pkgs.writeText "livesync.ini" (import ./config/livesync.ini.nix {inherit hostConfig lib;});
in {
  main = {
    volumes = [
      "${scfg.dataDir}:/opt/couchdb/data"
      "${livesyncConfig}:/opt/couchdb/etc/local.ini:ro"
      "/var/log/obsidian-livesync/:/var/log/obsidian-livesync"
    ];
    network = [
      "revproxy.network"
    ];
    labels = {
      "traefik.enable" = "true";
      # "traefik.http.routers.obsidian.rule" = "Host(`${scfg.subdomain}.${hostConfig.domain}`) && (Path(`/`) || Path(`/_session`) || PathRegexp(`^/obsidian(/.*)\$`))";
      "traefik.http.routers.obsidian.rule" = "Host(`${scfg.subdomain}.${hostConfig.domain}`)";
      "traefik.docker.network" = "revproxy";
      "traefik.http.routers.obsidian.service" = "obsidian";
      "traefik.http.services.obsidian.loadbalancer.server.port" = "5984";
      "traefik.http.routers.obsidian.entrypoints" = "websec-exposed";
      "traefik.http.routers.obsidian.tls" = "true";
      "traefik.http.routers.obsidian.tls.certresolver" = "production";
    };
    environmentFile = [ config.sops.templates."obsidian-livesync.env".path ];
    extraConfig = {
      Container.HealthCmd = ''curl -fsS -u "$COUCHDB_USER:$COUCHDB_PASSWORD" http://127.0.0.1:5984/_up'';
      Unit = {
        Requires = ["sops-nix.service"];
        After = ["sops-nix.service"];
      };
    };
  };
}
