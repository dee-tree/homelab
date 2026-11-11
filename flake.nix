{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # dotfiles = {
    #   url = "github:dee-tree/dotfiles";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };

    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      # dotfiles,
      system-manager,
      home-manager,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      mkHost =
        hostModule:
        system-manager.lib.makeSystemConfig {
          modules = [
            home-manager.nixosModules.home-manager
            ./modules/core
            hostModule
          ];
        };
    in
    {
      systemConfigs = {
        deelime = mkHost ./hosts/deelime;
      };
    };
}
