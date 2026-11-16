{lib}: let
  inherit (lib) mkOption types;
in {
  acmeEmail = mkOption {
    type = types.str;
    description = "email for acme";
  };
}
