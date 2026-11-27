{
  name, # service name
  containers, # containers builder
  network ? false, # create private network
  homeExtra ? null, # home-manager module
  system ? null, # system-manager module
}: let
  mkService = import ./mk-service.nix;

  home = {
    config,
    hostConfig,
    lib,
    pkgs,
    ...
  }: let
    scfg = hostConfig.services.${name};
    user = hostConfig.users.${scfg.runtimeUser};
    args = {inherit config hostConfig scfg user lib pkgs;};
    cname = suffix:
      if suffix == "main"
      then name
      else "${name}-${suffix}";
    defs = containers args;
  in {
    imports = lib.optional (homeExtra != null) homeExtra;
    services.podman.enable = true;

    services.podman.networks = lib.optionalAttrs network {
      ${name} = {driver = "bridge";};
    };

    services.podman.containers = lib.mapAttrs' (suffix: container:
      lib.nameValuePair (cname suffix) (
        {
          autoStart = true;
          extraConfig = {
            Service = {
              Restart = "on-failure";
              RestartSec = "5s";
            };
            Container = {
              ContainerName = name;
              HealthInterval = "30s";
              HealthTimeout = "5s";
              HealthRetries = 3;
              HealthOnFailure = "kill";
            };
          };
          user = lib.mkIf (scfg.dataOwner.mode == "container") "${toString scfg.dataOwner.uid}:${toString scfg.dataOwner.gid}";
          image = lib.mkIf (suffix == "main") "${scfg.image}:${scfg.label}";
          ip4 = lib.mkIf (suffix == "main" && scfg.ip4 != null) scfg.ip4;
        }
        // lib.optionalAttrs network {network = [name];}
        // container
      ))
    defs;
  };
  # // lib.optionalAttrs (homeExtra != null) (homeExtra args);
in
  mkService {inherit name home system;}
