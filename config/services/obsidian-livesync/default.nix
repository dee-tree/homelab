{scfg, pkgs, ...}: {
  runtimeUser = "worker";
  image = "docker.io/library/couchdb";
  label = import ./version.nix;
  ip4 = "10.90.0.30";

  backup.exporter.enable = true;
  backup.exporter.sources = [
    scfg.dataDir
  ];
  backup.exporter.preCommand = "${pkgs.systemd}/bin/systemctl --user --machine=worker@.host stop podman-obsidian-livesync.service";
  backup.exporter.postCommand = "${pkgs.systemd}/bin/systemctl --user --machine=worker@.host start podman-obsidian-livesync.service";
}
