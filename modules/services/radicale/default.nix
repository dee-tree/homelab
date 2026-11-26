{name}: {config, ...}: let
  mkPodmanService = import ../../../lib/mk-podman-service.nix;

  home = {
    hostConfig,
    lib,
    pkgs,
    ...
  }: let
    scfg = hostConfig.services.radicale;
  in {
    home.activation.radicaleData = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg scfg.dataDir}
      run ${pkgs.coreutils}/bin/chmod 0700 ${lib.escapeShellArg scfg.dataDir}
    '';
  };

  service = mkPodmanService {
    inherit name;
    containers = import ./stack.nix;
    homeExtra = home;
  };
in {
  imports = [service];
}
