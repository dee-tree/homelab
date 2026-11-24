{ ... }:
{
  users.groups.backup-readers = {
    gid = 890;
    members = [
      "worker" # TODO: homelab-worker
      "homelab-backup"
    ];
  };
}
