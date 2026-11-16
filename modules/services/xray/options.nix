{lib}: let
  inherit (lib) mkOption types mkEnableOption;
in {
  hostname = mkOption {
    type = types.str;
    description = "hostname where xray is hosted";
  };

  maskingSni = mkOption {
    type = types.str;
    description = "Masking SNI domain";
  };

  subscriptionSubPath = mkOption {
    type = types.str;
    default = "/"; # TODO: remove default
    description = "Path to subscriptions URL";
  };

  privateKey = mkOption {
    type = types.str;
    description = "Private key";
  };

  publicKey = mkOption {
    type = types.str;
    description = "Public key";
  };

  userIds = mkOption {
    type = types.listOf types.str;
    default = [];
    description = "xray users id";
  };

  userShortIds = mkOption {
    type = types.listOf types.str;
    default = [];
    description = "xray users short id";
  };

  userNames = mkOption {
    type = types.listOf types.str;
    default = [];
    description = "xray users names";
  };

  enableRealityInbound = mkEnableOption "Enable reality inbound";
}
