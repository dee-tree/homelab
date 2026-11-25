{
  lib,
  name,
  ...
}: let
  inherit (lib) mkEnableOption mkOption types;
  service = name;
in {
  options = {
    enable = mkEnableOption "Enable ${service} service";

    runtimeUser = lib.mkOption {
      type = lib.types.str;
      description = "System user that is running ${service} service; should be defined in `homelab.users`";
    };

    image = mkOption {
      # TODO: separate containerized services and others to avoid setting null
      type = types.nullOr types.str;
      description = "OCI image without label specified";
    };
    label = mkOption {
      type = types.nullOr types.str;
      description = "OCI image label. Pin by digest for strict reproducibility.";
    };

    ip4 = mkOption {
      type = types.nullOr types.str;
      description = "OCI image ipv4 address.";
    };

    subdomain = mkOption {
      type = lib.types.nullOr types.str;
      default = name;
      description = "Hosted ${name} subdomain";
    };

    volumes = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "Extra podman volume specs.";
    };

    backup.exporter = (import ./backup-exporter.nix {inherit lib;}).exporter service;

    verbose = mkEnableOption "Should verbose logging be enabled for the ${service}";
  };
}
