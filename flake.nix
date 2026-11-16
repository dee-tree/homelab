{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    config = {
      # TODO: Change config URL
      # url = "github:dee-tree/homelab.config";
      url = "path:./config";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      system-manager,
      home-manager,
      config,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      # system = "x86_64-linux";
      # pkgs = nixpkgs.legacyPackages.${system};
      evalTimeSecrets = lib.recursiveUpdate (import ./config) (import "${config}");

      hostnames = builtins.attrNames (
        lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts)
      );
      # all hosts enumeration
      instances = lib.unique (hostnames ++ builtins.attrNames evalTimeSecrets);

      mkHost =
        hostname:
        let
          secrets = evalTimeSecrets.${hostname} or { };
        in
        if !(builtins.elem hostname hostnames) then
          throw "homelab: host '${hostname}' is not declared (expected hosts/${hostname}/)"
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
    };
}
