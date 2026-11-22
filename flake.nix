{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";

    system-manager = {
      url = "github:numtide/system-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    secrets = {
      # Ensure ssh key is grant for github and repo is available.
      # Otherwise, override the input in CLI: `--override-input secrets <url>`
      url = "git+ssh://git@github.com/dee-tree/homelab.secrets.git";
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
    sops-nix,
    ...
  }: let
    inherit (nixpkgs) lib;
    configModule = lib.recursiveUpdate
      (import ./config { inherit lib; }) # low priority host-level defaults
      secrets.configModule; # higher priority config

    hostnames = builtins.attrNames (
      lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./hosts)
    );
    # all hosts enumeration
    instances = lib.unique (hostnames ++ builtins.attrNames configModule);

    mkHost = hostname: let
      cfg = configModule.${hostname} or {};
    in
      if !(builtins.elem hostname hostnames)
      then throw "homelab: host '${hostname}' is not declared (expected hosts/${hostname}/)"
      else
        system-manager.lib.makeSystemConfig {
          modules = [
            home-manager.nixosModules.home-manager
            self.systemModules.homelab
            ./hosts/${hostname}
            secrets.secretsModule.${hostname}
            {
              nixpkgs.hostPlatform = lib.mkIf (cfg ? system) cfg.system;
              homelab = cfg;
            }
            {
              home-manager.users.worker.imports = [
                sops-nix.homeManagerModules.sops
              ];
            }
          ];
        };
  in
    rec {
      systemModules.homelab = ./modules;
      # For each host, declare system with system-manager
      systemConfigs = lib.genAttrs instances mkHost;

      # Exposed for nix eval
      hostConfig =
        builtins.mapAttrs
        (_host: system: system.config.homelab)
        systemConfigs;
    }
    // import ./shells {
      inherit nixpkgs flake-utils;
    }
    // import ./lib {
      inherit (nixpkgs) lib;
      inherit (self) systemConfigs;
    };
}
