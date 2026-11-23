{...}: {
  image = "docker.io/teddysun/xray";
  label = import ./version.nix;
  ip4 = "10.90.0.11";
  backup.exporter.disableWithReason = "No persistant structure to backup";
}
