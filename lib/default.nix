{
  systemConfigs,
  lib,
  ...
}: let
  mkXrayRealityClientUri = import ./mk-xray-reality-client-uri.nix {
    inherit lib;
  };

  mkXrayClientUri = {
    cfg,
    host,
    clientName,
  }: let
    scfg = cfg.services.xray;
    client =
      lib.findFirst
      (client: (client.username or "") == clientName)
      (throw "Xray client ${clientName} not found")
      scfg.vlessClients;
  in
    mkXrayRealityClientUri {
      inherit client;

      host = cfg.domain;
      publicKey = scfg.publicKey;

      serverName = scfg.maskingSni;
      name = "${host}";
    };
in {
  lib = {
    xrayClientUri =
      builtins.mapAttrs
      (host: system: let
        cfg = system.config.homelab;
        scfg = cfg.services.xray;
        clientNames = map (client: client.username) scfg.vlessClients;
      in
        builtins.listToAttrs (
          map (clientName: {
            name = clientName;
            value = mkXrayClientUri {
              inherit cfg host clientName;
            };
          })
          clientNames
        ))
      systemConfigs;
  };
}
