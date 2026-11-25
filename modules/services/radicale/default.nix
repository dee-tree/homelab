{name}: {config, ...}: let
  mkPodmanService = import ../../../lib/mk-podman-service.nix;

  home = {
    config,
    lib,
    pkgs,
    ...
  }: let
    dataDir = "${config.home.homeDirectory}/data/radicale";
  in {
    home.activation.radicaleData = lib.hm.dag.entryAfter ["writeBoundary"] ''
      run ${pkgs.coreutils}/bin/mkdir -p ${lib.escapeShellArg dataDir}
      run ${pkgs.coreutils}/bin/chmod 0700 ${lib.escapeShellArg dataDir}
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
