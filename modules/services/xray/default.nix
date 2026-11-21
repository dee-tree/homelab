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
  scfg = cfg.services.xray;
  xrayConfig = import ./config/config.nix {
    inherit lib cfg;
    privateKey = config.sops.placeholder."xray/vless/private_key";
  };
in {
  # TODO: consider exposing "xray-config.json".path from secrets
  # to avoid sops-templating it here.
  sops.templates."xray-config.json" = lib.mkIf scfg.enable {
    mode = "0400";
    content = builtins.toJSON xrayConfig;
  };

  services.podman = {
    enable = true;

    containers.xray = lib.mkIf scfg.enable {
      image = "${scfg.image}:${scfg.label}";
      volumes = [
        "${config.sops.templates."xray-config.json".path}:/etc/xray/config.json:ro"
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
        Unit = {
          Requires = ["sops-nix.service"];
          After = ["sops-nix.service"];
        };
      };
    };
  };
}
