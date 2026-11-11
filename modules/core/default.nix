{ pkgs, ... }:

{
  services.userborn.enable = true;
  services.userborn.package = pkgs.lib.mkForce pkgs.userborn;

  # Required by the documented Home Manager integration.
  nix.enable = true;
  nix.settings.trusted-users = [
    "root"
    "dee"
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };
}
