{ ... }:
{
  users.groups.backup-readers = {
    gid = 890;
    members = [
      "worker"
      "backup"
    ];
  };
}
