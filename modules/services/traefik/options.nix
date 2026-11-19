{lib}: let
  inherit (lib) mkOption types mkEnableOption;
in {
  acmeEmail = mkOption {
    type = types.str;
    description = "email for acme";
  };

  enableDashboard = mkEnableOption "enable traefik dashboard";
  enablePrometheusMetrics = mkEnableOption "enable traefik prometheus metrics export";
}
