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

    image = mkOption {
      type = types.str;
      description = "OCI image without label specified";
    };
    label = mkOption {
      type = types.str;
      description = "OCI image label. Pin by digest for strict reproducibility.";
    };

    ip4 = mkOption {
      type = types.str;
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

    verbose = mkEnableOption "Should verbose logging be enabled for the ${service}";
  };
}
