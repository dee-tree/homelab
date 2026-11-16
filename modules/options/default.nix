# Schema for homelab config.
# The single option tree shared by the system and Home Manager layers.
{lib, ...}: let
  inherit (lib) mkOption mkEnableOption types;

  # Restrict to characters that are safe inside nginx config and shell args.
  hostnameType = types.strMatching "[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?";

  mkServiceOpts = import ./service-options.nix {
    inherit lib;
  };

  services = builtins.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../services)
  );
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

    user = mkOption {
      type = types.str;
      default = "worker";
      description = "System user owning the service and running it";
    };

    userId = mkOption {
      type = types.int;
      default = 800;
      description = "System user ID capable running this service";
    };

    subIdStart = mkOption {
      type = types.int;
      default = 200000;
      description = "start of range mapping for the podman";
    };

    domain = mkOption {
      type = types.str;
      description = "Domain name backed the server";
    };

    services = lib.genAttrs services (service: mkServiceOpts {options = import ../services/${service}/options.nix {inherit lib;};});
  };
}
