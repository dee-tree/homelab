# home-manager service
{cfg, ...}: {
  lib,
  pkgs,
  ...
}:
# arguments are supplied by home-manager
let
  scfg = cfg.services.traefik;
  crowdsecConf = pkgs.writeText "crowdsec.yaml" (import ./config/dynamic.crowdsec.yaml.nix {inherit lib cfg;});
  dynamicConfigDir = "/etc/traefik/dynamic/conf";
  certsDir = "/etc/traefik/certs";
in {
  services.podman = {
    enable = true;

    containers.traefik = lib.mkIf scfg.enable {
      image = "${scfg.image}:${scfg.label}";

      volumes = [
        "${crowdsecConf}:/${dynamicConfigDir}/crowdsec.yaml" # Routing/dynamic configuration
        "/var/lib/traefik/secrets:/run/traefik/secrets:ro" # crowdsec LAPI key
        "%t/podman/podman.sock:/var/run/docker.sock"
        "/var/lib/traefik/acme/acme.json:${certsDir}/acme.json" # SSL certificates
        "/var/lib/traefik/acme/acme-staging.json:${certsDir}/acme-staging.json" # SSL certificates

        "/var/log/traefik:/var/log/traefik"
      ];
      network = [
        "revproxy.network"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.dashboard.rule" = "Host(`${scfg.subdomain}.${cfg.domain}`)";
        "traefik.http.routers.dashboard.service" = "api@internal";
        "traefik.http.routers.dashboard.entrypoints" = "websec";
        # "traefik.http.routers.dashboard.tls.certresolver" = "production"
        "traefik.http.routers.dashboard.tls" = "true";
      };
      ip4 = scfg.ip4;
      autoStart = true;
      extraConfig = {
        Container.ContainerName = "traefik";
        Container.Exec = builtins.concatStringsSep " " [
          # Providers
          "--providers.docker=true"
          "--providers.docker.endpoint=unix:///var/run/docker.sock"
          # Do not enable traefik for containers by default without explicit `traefik.enable=true` label
          "--providers.docker.exposedbydefault=false"
          "--providers.docker.network=revproxy"

          # Dynamic/routing configuration
          "--providers.file.directory=${dynamicConfigDir}"

          # Entry points
          # # "exposed" services are accessible from Internet
          "--entrypoints.web-exposed.address=:80"
          "--entrypoints.web-exposed.http.redirections.entrypoint.to=websec-exposed"
          "--entrypoints.web-exposed.http.redirections.entrypoint.scheme=https"

          "--entrypoints.websec-exposed.address=:443"
          "--entrypoints.websec-exposed.http.tls=true"
          "--entrypoints.websec-exposed.http.tls.certresolver=production"
          # trust nginx & xray
          "--entrypoints.websec-exposed.proxyProtocol.trustedIPs=10.90.0.10/32,10.90.0.11/32"
          "--entrypoints.websec-exposed.http.middlewares=crowdsec@file"

          # # "non-exposed" services are accessible within LAN
          # TODO: requires investigation how to make it work
          "--entrypoints.web.address=:88"
          "--entrypoints.web.http.redirections.entrypoint.to=websec"
          "--entrypoints.web.http.redirections.entrypoint.scheme=https"

          "--entrypoints.websec.address=:4433"
          "--entrypoints.websec.http.tls=true"
          # Inernal paths are not accessible outside for acme challenge.
          # - --entrypoints.websec.http.tls.certresolver=production

          # Certificates
          "--certificatesresolvers.staging.acme.email=${scfg.acmeEmail}"
          "--certificatesresolvers.staging.acme.storage=${certsDir}/acme-staging.json"
          "--certificatesresolvers.staging.acme.tlschallenge=true"
          "--certificatesresolvers.staging.acme.caserver=https://acme-staging-v02.api.letsencrypt.org/directory"

          "--certificatesresolvers.production.acme.email=${scfg.acmeEmail}"
          "--certificatesresolvers.production.acme.storage=${certsDir}/acme.json"
          "--certificatesresolvers.production.acme.tlschallenge=true"
          "--certificatesresolvers.production.acme.caserver=https://acme-v02.api.letsencrypt.org/directory"

          # Observability
          "--log.filePath=/var/log/traefik/traefik.log"
          "--log.format=json"
          "--log.maxAge=360"
          "--log.maxSize=5" # Mb
          "--log.level=WARN"
          # "--log.level=DEBUG"

          "--accesslog=true"
          "--accesslog.filePath=/var/log/traefik/access.log"
          "--accesslog.format=json"
          # - --accesslog.filters.statuscodes=200,300-302,400-404,500-504

          "--metrics.prometheus=${lib.boolToString scfg.enablePrometheusMetrics}" # TODO: prometheus configurable
          "--metrics.prometheus.addEntryPointsLabels=true"
          "--metrics.prometheus.addServicesLabels=true"
          "--entryPoints.metrics.address=:8001"
          "--metrics.prometheus.entryPoint=metrics"
          "--api.dashboard=${lib.boolToString scfg.enableDashboard}"
          "--api.insecure=false"

          "--ping" # for healthcheck

          # crowdsec plugin
          # https://github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin
          "--experimental.plugins.bouncer.modulename=github.com/maxlerebourg/crowdsec-bouncer-traefik-plugin"
          "--experimental.plugins.bouncer.version=v1.8.2"
        ];
        Container.HealthCmd = builtins.toJSON [
          "traefik"
          "healthcheck"
          "--ping"
        ];
        Container.HealthInterval = "30s";
        Container.HealthTimeout = "5s";
        Container.HealthRetries = 3;
        Container.HealthOnFailure = "kill";

        Service = {
          Restart = "on-failure";
          RestartSec = "5s";
        };
        Unit = {
          Requires = ["podman.socket"];
          After = ["podman.socket"];
        };
      };
    };


    containers.webserver = lib.mkIf scfg.enable {
      image = "docker.io/nginxdemos/hello:latest";
      network = [
        "revproxy.network"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.docker.network" = "revproxy";
        "traefik.http.routers.webserver.rule" ="Host(`www.${cfg.domain}`)";
        "traefik.http.services.webserver.loadbalancer.server.port" = "80";
        "traefik.http.routers.webserver.entrypoints" = "websec-exposed,web-exposed";
        "traefik.http.routers.webserver.service" = "webserver";
        "traefik.http.routers.webserver.tls" = "true";
        "traefik.http.routers.webserver.tls.certresolver" = "production";
      };
      autoStart = true;
      extraConfig = {
        Container.ContainerName = "webserver";
        Service = {
          Restart = "on-failure";
          RestartSec = "5s";
        };
      };
    };
  };
}
