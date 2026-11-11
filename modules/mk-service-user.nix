{
  user,
  uid,
  gid ? uid,
  subIdStart,
  homeModule
}:
{ pkgs, ... }: # arguments are supplied by system-manager
{
  users.groups.${user} = {
    inherit gid;
  };

  users.users.${user} = {
    inherit uid;

    group = user;
    isSystemUser = true;

    home = "/var/lib/${user}";
    createHome = true;
    linger = true;

    # Reserve a non-overlapping range on this host.
    subUidRanges = [
      {
        startUid = subIdStart;
        count = 65536;
      }
    ];

    subGidRanges = [
      {
        startGid = subIdStart;
        count = 65536;
      }
    ];
  };

  security.wrappers = {
    newuidmap = {
      source = "${pkgs.shadow.out}/bin/newuidmap";
      setuid = true;
      owner = "root";
      group = "root";
    };
    newgidmap = {
      source = "${pkgs.shadow.out}/bin/newgidmap";
      setuid = true;
      owner = "root";
      group = "root";
    };
  };

  home-manager.users.${user} = {
    imports = [
      homeModule
    ];

    # Keep this unchanged after initial deployment.
    home.stateVersion = "26.05";
  };
}
