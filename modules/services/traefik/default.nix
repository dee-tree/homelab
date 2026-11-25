{name}: {config, ...}: let
  mkPodmanService = import ../../../lib/mk-podman-service.nix;

  service = mkPodmanService {
    inherit name;
    containers = import ./stack.nix;
  };
in {
  imports = [service];
}
