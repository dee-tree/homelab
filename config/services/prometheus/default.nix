{...}: {
  runtimeUser = "worker";
  image = "quay.io/prometheus/prometheus";
  label = import ./version.nix;
  ip4 = "10.90.0.30";
  backup.exporter.disableWithReason = "No need to backup monitoring data";
}
