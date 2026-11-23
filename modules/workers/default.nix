{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.homelab;
  mkServiceUser = import ./mk-service-user.nix;
  services = builtins.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../services)
  );

  homeModule = {config, ...}: let
    importService = service: (import ../services/${service} {
      inherit cfg config;
    });
  in {
    imports = map importService services;
    sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";

    xdg.configFile."containers/containers.conf.d/10-timezone.conf".text = ''
      [containers]
      tz = "${cfg.timezone}"

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
  };

  user = mkServiceUser {
    inherit (cfg) enable;
    user = cfg.user;
    uid = cfg.userId;
    subIdStart = cfg.subIdStart;
    inherit homeModule;
  };
in {
  imports = [user ../services/crowdsec/firewall-bouncer.nix ./backup-reader-group.nix];
}
