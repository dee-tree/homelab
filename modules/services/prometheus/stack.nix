{
  config,
  hostConfig,
  scfg,
  lib,
  pkgs,
  ...
}: let
prometheusConfig = import ./config/prometheus.yml.nix { inherit pkgs; };
in {
  main = {
    # Run as root inside rootless container, mapping to worker on the host
    volumes = [
      "${prometheusConfig}:/etc/prometheus/prometheus.yml:ro"
      "${rulesFile}:/etc/prometheus/rules.yml:ro"
      "${stateDir}:/prometheus"
    ];
    labels = {
    };
    network = [
      # "revproxy.network"
    ];
    extraConfig = {
    };
  };
}
