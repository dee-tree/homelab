{lib, ...}: let
  hostnames = builtins.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ../hosts)
  );
  services = builtins.attrNames (
    lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./services)
  );
  mkHostConfig = host: {
    services = lib.genAttrs services (
      service:
        import ./services/${service}
    );
  };
in (lib.genAttrs hostnames mkHostConfig)
