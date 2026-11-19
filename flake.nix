{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    secrets = {
      url = "github:dee-tree/homelab.secrets";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    system-manager,
    home-manager,
    secrets,
    ...
  }: let
    inherit (nixpkgs) lib;
    # system = "x86_64-linux";
    # pkgs = nixpkgs.legacyPackages.${system};
    configModule = lib.recursiveUpdate (import ./config) (secrets.configModule);

    hostnames = builtins.attrNames (
      lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts)
    );
    # all hosts enumeration
    instances = lib.unique (hostnames ++ builtins.attrNames configModule);

    mkHost = hostname: let
      secrets = configModule.${hostname} or {};
    in
      if !(builtins.elem hostname hostnames)
      then throw "homelab: host '${hostname}' is not declared (expected hosts/${hostname}/)"
      else
        system-manager.lib.makeSystemConfig {
          modules = [
            home-manager.nixosModules.home-manager
            self.systemModules.homelab
            ./hosts/${hostname}
            {
              nixpkgs.hostPlatform = lib.mkIf (secrets ? system) secrets.system;
              homelab = secrets;
            }
          ];
        };
  in
    {
      systemModules.homelab = ./modules;
      # For each host, declare system with system-manager
      systemConfigs = lib.genAttrs instances mkHost;
      inherit configModule;
    }
    // import ./shells {
      inherit nixpkgs flake-utils;
    };
}
