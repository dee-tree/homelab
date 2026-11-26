{config, scfg, lib, ...}: {
  main = {
    volumes = [
      "${config.sops.templates."xray-config.json".path}:/etc/xray/config.json:ro"
      "/var/log/xray:/var/log/xray"
    ];
    network = [
      "revproxy.network"
    ];
    extraConfig = {
      Container = lib.mkIf (scfg.enableVlessInbound) {
        HealthCmd = "nc -z 127.0.0.1 ${toString 443}";
      };
      Unit = {
        Requires = ["sops-nix.service"];
        After = ["sops-nix.service"];
      };
    };
  };
}
