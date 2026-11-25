{config, ...}: {
  main = {
    volumes = [
      "${config.sops.templates."xray-config.json".path}:/etc/xray/config.json:ro"
      "/var/log/xray:/var/log/xray"
    ];
    network = [
      "revproxy.network"
    ];
    extraConfig = {
      Unit = {
        Requires = ["sops-nix.service"];
        After = ["sops-nix.service"];
      };
    };
  };
}
