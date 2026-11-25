{...}: {
  runtimeUser = "worker";
  image = "docker.io/crowdsecurity/crowdsec";
  label = import ./version.nix;
  ip4 = "10.90.0.13";
  backup.exporter.disableWithReason = "No persistant structure to backup";
}
