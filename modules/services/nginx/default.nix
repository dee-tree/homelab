{name}: {...}: let
  mkPodmanService = import ../../../lib/mk-podman-service.nix;

  service = mkPodmanService {
    inherit name;
    containers = import ./stack.nix;
    homeExtra = {...}: {
      services.podman.networks.revproxy = {
        driver = "bridge";
        subnet = "10.90.0.0/24";
        gateway = "10.90.0.1";
      };
    };
  };
in {
  imports = [service];
}
