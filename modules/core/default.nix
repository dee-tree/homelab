{
  config,
  pkgs,
  ...
}: let
  cfg = config.homelab;
  services = builtins.attrNames (
    pkgs.lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../services)
  );
  mapNonNull = f: list:
    builtins.filter (value: value != null) (map f list);
  logDirs = mapNonNull (service:
    if cfg.services.${service}.enable
    then "d /var/log/${service} 0750 ${cfg.users.worker.name} ${cfg.users.worker.name} -"
    else null)
  services;
in {
  services.userborn.enable = true;
  # It's required to use fresh userborn fron nixpkgs instead of pinned by system-manager
  # # because it's currently (Nov, 2026) outdated and does not provide subUidMapping
  services.userborn.package = pkgs.lib.mkForce pkgs.userborn;

  # Required by the documented Home Manager integration.
  nix.enable = true;
  nix.settings.trusted-users = [
    "root"
    "dee"
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  systemd.tmpfiles.rules = logDirs ++
  [
    "d /var/lib/traefik/acme 0700 ${cfg.users.worker.name} ${cfg.users.worker.name} -"
    "f /var/lib/traefik/acme/acme.json 0600 ${cfg.users.worker.name} ${cfg.users.worker.name} -"
    "f /var/lib/traefik/acme/acme-staging.json 0600 ${cfg.users.worker.name} ${cfg.users.worker.name} -"
    "d /var/lib/traefik/secrets 0700 ${cfg.users.worker.name} ${cfg.users.worker.name} -"

    "d /var/lib/crowdsec 0700 ${cfg.users.worker.name} ${cfg.users.worker.name} -"
    "d /var/lib/crowdsec/config 0700 ${cfg.users.worker.name} ${cfg.users.worker.name} -"
    "d /var/lib/crowdsec/data 0700 ${cfg.users.worker.name} ${cfg.users.worker.name} -"
  ];

  # allow access to exposing http/https ports
  environment.etc."sysctl.d/90-rootless-ingress.conf".text = ''
    net.ipv4.ip_unprivileged_port_start = 80
  '';
}
