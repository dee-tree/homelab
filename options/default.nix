# The single option tree shared by the system and Home Manager layers.
{ lib, ... }:
let
  inherit (lib) mkOption mkEnableOption types;

  # Restrict to characters that are safe inside nginx config and shell args.
  hostnameType = types.strMatching "[A-Za-z0-9]([A-Za-z0-9.-]*[A-Za-z0-9])?";

  serviceType = types.submodule (
    { name, ... }:
    {
      options = {
        image = mkOption {
          type = types.str;
          description = "OCI image without label specified";
        };
        label = mkOption {
          type = types.str;
          description = "OCI image label. Pin by digest for strict reproducibility.";
        };
        port = mkOption {
          type = types.port;
          default = 80;
          description = "Port the application listens on inside the container.";
        };
        hostPort = mkOption {
          type = types.port;
          description = "Loopback port on the host (127.0.0.1)";
        };
        environment = mkOption {
          type = types.attrsOf types.str;
          default = { };
          description = "Non-secret container environment. Use runtime files for credentials.";
        };
        volumes = mkOption {
          type = types.listOf types.str;
          default = [ ];
          description = "Extra podman volume specs.";
        };

        user = mkOption {
          type = types.str;
          default = "worker";
          description = "System user capable running this service";
        };
        userId = mkOption {
          type = types.int;
          description = "System user ID capable running this service";
        };
      };
    }
  );
in
{
  options.homelab = {
    enable = mkEnableOption "enable hosting on specified node";

    # user = mkOption {
    #   type = types.str;
    #   default = "svc";
    #   description = "Service account that owns the rootless containers.";
    # };
    # uid = mkOption {
    #   type = types.int;
    #   default = 2000;
    #   description = "Fixed UID/GID for the service account (reproducible /run/user/<uid>).";
    # };
    home = mkOption {
      type = types.str;
      default = "/var/lib/worker";
      description = "Home and state directory of the service account.";
    };

    hostname = mkOption {
      type = hostnameType;
      default = "localhost";
      description = "Public hostname";
    };
    services = mkOption {
      type = types.attrsOf serviceType;
      default = { };
      description = "Backends hosted behind nginx; the attribute name is the container name.";
    };
  };
}
