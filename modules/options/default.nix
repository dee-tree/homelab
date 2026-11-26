# Schema for homelab config.
# The single option tree shared by the system and Home Manager layers.
{
  config,
  lib,
  ...
}: let
  cfg = config.homelab;
  inherit (lib) mkOption mkEnableOption types;

  # Restrict to characters that are safe inside nginx config and shell args.
  hostnameType = types.strMatching "[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?";

  mkServiceOpts = serviceOptions:
    mkOption {
      default = {};
      type = lib.types.submodule {
        imports = [
          ./service-common.nix
          serviceOptions
        ];
      };
    };

  services = builtins.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../services)
  );

  user = name: id: subUidShift: description: {
    ${name} = {
      name = mkOption {
        type = types.str;
        default = "${name}";
        description = description;
      };
      id = mkOption {
        type = types.int;
        default = id;
        description = "system '${name}' user uid";
      };
      subIdStart = mkOption {
        type = types.int;
        default = subUidShift * 100000 + 200000;
        description = "start of range mapping for the podman";
      };
    };
  };
in {
  options.homelab = {
    enable = mkEnableOption "Enable hosting on specified node";

    hostname = mkOption {
      type = hostnameType;
      default = "localhost";
      description = "Public hostname";
    };

    timezone = mkOption {
      type = types.str;
      default = "Europe/London";
      description = "Host timezone";
    };

    users = lib.mergeAttrsList [
      (user "worker" 800 0 "System user capable running services")
      (user "backup" 891 1 "System user capable backing services persistend data up")
    ];

    domain = mkOption {
      type = types.str;
      description = "Domain name backed the server";
    };

    verbose = mkEnableOption "Should verbose logging be enabled for the whole host";

    services = lib.genAttrs services (
      service:
        mkServiceOpts {
          options = import ../services/${service}/options.nix {
            inherit config cfg lib;
            scfg = cfg.services.${service};
          };
        }
    );
  };
}
