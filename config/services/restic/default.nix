{...}: {
  backup.exporter.disableWithReason = "Backup tool itself";

  repositories.dummy = {
    enable = true;
    repository = "/tmp/homelab/restic/dummy";
    extraOptions = ["--insecure-no-password"];
  };
}
