{lib}: serviceOptions:
lib.mkOption {
  default = {};

  type = lib.types.submodule {
    imports = [
      ./service-common.nix
      serviceOptions
    ];
  };
}
