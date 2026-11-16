{ lib, ... }:
let
  defaultSystem = "x86_64-linux";
in
{
  nixpkgs.hostPlatform = lib.mkDefault defaultSystem;

  homelab = rec {
    enable = true;
    timezone = "Europe/London";
    domain = "DOMAIN.com";
    services = {
      nginx = {
        enable = false;
      };
      xray.enable = false;
      xray = {
        maskingSni = "DOMAIN.com";
        hostname = domain;
        privateKey = "";
        publicKey = "";

        userIds = [ "" ];
        userNames = [ "device1" ];
        userShortIds = [ "" ];
      };
    };
  };
}
