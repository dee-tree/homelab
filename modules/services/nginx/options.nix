{lib, ...}: let
  inherit (lib) mkOption types;
in {
  httpPort = mkOption {
    type = types.port;
    default = 80;
    description = "Host http port for nginx";
  };
  httpsPort = mkOption {
    type = types.port;
    default = 443;
    description = "Host https port for nginx";
  };
}
