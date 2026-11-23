{...}: {
  image = "docker.io/library/traefik";
  label = import ./version.nix;
  ip4 = "10.90.0.12";
  backup.exporter.disableWithReason = "No persistant structure to backup";
}
