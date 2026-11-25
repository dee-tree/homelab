{ name }:
{ ... }:
let
mkPodmanService = import ../../../lib/mk-podman-service.nix;

service = mkPodmanService {
  inherit name;
  system = import ./firewall-bouncer.nix;
  containers = import ./stack.nix;
};
in
{
  imports = [ service ];
}
