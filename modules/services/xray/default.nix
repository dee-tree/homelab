{name}: {...}: let
  mkPodmanService = import ../../../lib/mk-podman-service.nix;

  home = {
    config,
    hostConfig,
    lib,
    ...
  }: let
    scfg = hostConfig.services.xray;
    xrayConfig = import ./config/config.nix {
      inherit lib;
      cfg = hostConfig;
      privateKey = config.sops.placeholder."xray/vless/private_key";
    };
  in {
    # TODO: consider exposing "xray-config.json".path from secrets
    # to avoid sops-templating it here.
    sops.templates."xray-config.json" = lib.mkIf scfg.enable {
      mode = "0400";
      content = builtins.toJSON xrayConfig;
    };
  };

  service = mkPodmanService {
    inherit name;
    containers = import ./stack.nix;
    homeExtra = home;
  };
in {
  imports = [service];
}
