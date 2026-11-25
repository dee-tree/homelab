{ config, ... }:
let
  users = config.homelab.users;
in
{
  users.groups.backup-readers = {
    gid = 890;
    members = [
      users.worker.name
      users.backup.name
    ];
  };
}
