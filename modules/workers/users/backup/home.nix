{
  config,
  hostConfig,
  pkgs,
  ...
}: {
  home.packages = with pkgs; [
    restic
  ];

  sops.age.keyFile = "${config.home.homeDirectory}/.config/sops/age/keys.txt";
}
