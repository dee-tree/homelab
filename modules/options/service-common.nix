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

    dataOwner = {
      mode = lib.mkOption {
        type = lib.types.enum ["runtime" "container" "host"];
        default = "runtime";
        description = ''
          runtime   - owned by the runtime account (native services, no root podman)
          container - owned by container IDs, translated by `podman unshare`
          host      - explicit host user and group names (system services)
        '';
      };
      uid = lib.mkOption {
        type = lib.types.nullOr lib.types.ints.unsigned;
        default = null;
      };
      gid = lib.mkOption {
        type = lib.types.nullOr lib.types.ints.unsigned;
        default = null;
      };
      user = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      group = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
    };

    backup.exporter = (import ./backup-exporter.nix {inherit lib;}).exporter service;

    verbose = mkEnableOption "Should verbose logging be enabled for the ${service}";
  };
}
