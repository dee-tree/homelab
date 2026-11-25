{ hostConfig, pkgs, ... }:
{
  services.podman.enable = true;
  home.packages = [ pkgs.podman ];

  xdg.configFile."containers/containers.conf.d/10-timezone.conf".text = ''
    [containers]
    tz = "${hostConfig.timezone}"

    [network]
    rootless_port_forwarder = "pasta"
  '';
  systemd.user.sockets.podman = {
    Unit.Description = "Podman API socket";

    Socket = {
      ListenStream = "%t/podman/podman.sock";
      SocketMode = "0600";
    };

    Install.WantedBy = ["sockets.target"];
  };

  systemd.user.services.podman = {
    Unit = {
      Description = "Podman API service";
      Requires = ["podman.socket"];
      After = ["podman.socket"];
    };

    Service = {
      Type = "exec";
      ExecStart = "${pkgs.podman}/bin/podman system service --time=0";
      KillMode = "process";
    };
  };
  # Required for getting real user IP within containers
  # See: https://github.com/podman-container-tools/podman/discussions/30141
  xdg.configFile."containers/containers.conf".text = ''
    [network]
    rootless_port_forwarder = "pasta"
  '';
}
