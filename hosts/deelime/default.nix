{ lib, ... }:
let
  defaultSystem = "x86_64-linux";
in
{
  nixpkgs.hostPlatform = lib.mkDefault defaultSystem;

  homelab = {
    enable = true;
    services.nginx.enable = true;
    services.xray.enable = true;
    services.traefik.enable = true;
    services.crowdsec.enable = true;
    services.radicale.enable = true; # TODO: remove radicale from deelime
    services.restic.enable = true;
  };
}
