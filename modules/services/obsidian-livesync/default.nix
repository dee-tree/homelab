{name}: {...}: let
  mkPodmanService = import ../../../lib/mk-podman-service.nix;

  home = {
    config,
    hostConfig,
    ...
  }: let
    scfg = hostConfig.services.obsidian-livesync;
  in {
    sops.templates."obsidian-livesync.env".content = ''
      COUCHDB_USER=${config.sops.placeholder."obsidian-livesync/couchdb_user"}
      COUCHDB_PASSWORD=${config.sops.placeholder."obsidian-livesync/couchdb_password"}
    '';
    home.activation.couchdbDirs = config.lib.dag.entryBefore ["writeBoundary"] ''
      mkdir -p ${scfg.dataDir}/data
    '';
  };

  service = mkPodmanService {
    inherit name;
    containers = import ./stack.nix;
    homeExtra = home;
  };
in {
  imports = [service];
}
