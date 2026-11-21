{lib}: let
  inherit (lib) mkOption types mkEnableOption;

  vlessClientOption = types.submodule {
    options = {
      id = mkOption {
        type = types.str;
        description = "vless client id";
      };

      sid = mkOption {
        type = types.str;
        description = "vless client short id";
      };

      username = mkOption {
        type = types.str;
        description = "vless client name / email";
      };
    };
  };
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

  publicKey = mkOption {
    type = types.str;
    description = "Public key";
  };

  vlessClients = mkOption {
    type = types.listOf vlessClientOption;
    default = [];
    description = "xray vless client specification";
  };

  enableVlessInbound = mkEnableOption "Enable vless reality inbound";
}
