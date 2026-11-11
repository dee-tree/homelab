{  ... }:
let
  system = "x86_64-linux";
in
{
  nixpkgs.hostPlatform = system;

  imports = [
    ../../modules/nginx
  ];

}
