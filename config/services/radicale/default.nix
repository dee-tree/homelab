{pkgs, ...}: {
  image = "ghcr.io/kozea/radicale";
  label = import ./version.nix;
  ip4 = "10.90.0.20";

  backup.exporter.enable = true;
  backup.exporter.sources = [
    "/var/lib/worker/data/radicale"
  ];
  backup.exporter.preCommand = "${pkgs.systemd}/bin/systemctl --user --machine=worker@.host stop podman-radicale.service";
  backup.exporter.postCommand = "${pkgs.systemd}/bin/systemctl --user --machine=worker@.host start podman-radicale.service";
}
