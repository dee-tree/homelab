{lib}: let
  inherit (lib) mkOption types;
in {
  usersFile =
      mkOption {
        type = types.nullOr types.str;
        default = null;

        description = ''
          Host-side runtime file containing the users auth data.
        '';
      };
}
