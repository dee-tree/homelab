{pkgs, ...}: {
  runtimeUser = "backup";
  backup.exporter.disableWithReason = "Backup tool itself";

  repositories.dummy = {
    enable = true;
    repository = "/tmp/homelab/restic/dummy";
    passwordFile = "${(pkgs.writeText "restic-dummy-password" "12345")}";
  };
}
