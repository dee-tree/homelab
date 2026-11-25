{lib, ...}: let
  inherit (lib) mkOption types mkEnableOption;
in {
  traefikBouncer.apiKeyFile =
      mkOption {
        type = types.nullOr types.str;
        default = null;

        description = ''
          Host-side runtime file containing the Traefik bouncer's
          CrowdSec LAPI key. The file is mounted read-only into Traefik.
        '';
      };

      firewallBouncer.apiKeyFile =
          mkOption {
            type = types.nullOr types.str;
            default = null;

            description = ''
              Host-side runtime file containing the firewall bouncer's
              CrowdSec LAPI key. The file is mounted read-only into Traefik.
            '';
          };
}
