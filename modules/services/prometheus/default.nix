{name}: {config, ...}: let
  mkPodmanService = import ../../../lib/mk-podman-service.nix;

  home = {
    config,
    lib,
    pkgs,
    ...
  }: let
  in {
  };

  service = mkPodmanService {
    inherit name;
    containers = import ./stack.nix;
    homeExtra = home;
  };
in {
  imports = [service];
}
