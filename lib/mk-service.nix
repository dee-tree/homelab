{
  name, # service name
  home, # home-manager module
  system ? null, # system-manager module: { config, lib, scfg, user }: ...
}:

{ config, lib, pkgs, ... }:

let
  cfg = config.homelab;
  scfg = cfg.services.${name};
  users = cfg.users;
  knownUsers = lib.concatStringsSep ", " (builtins.attrNames users);
  userOk = users ? ${scfg.runtimeUser}; # guard in case if attribute does not exist
  user = users.${scfg.runtimeUser};
in
{
  config = lib.mkIf scfg.enable (lib.mkMerge [
    {
      assertions = [
        {
          assertion = userOk;
          message =
            "homelab.services.${name}.runtimeUser = \"${scfg.runtimeUser}\" "
            + "is not in homelab.users (known: ${knownUsers}).";
        }
      ];
    }

    (lib.mkIf userOk {
      home-manager.users.${user.name}.imports = [ home ];
    })

    (if system != null then lib.mkIf userOk (system {
      inherit config lib scfg user pkgs;
    }) else {})
  ]);
}
