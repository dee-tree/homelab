{
  config,
  hostConfig,
  pkgs,
  ...
}: {
  imports = [../../profiles/podman.nix];

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
}
