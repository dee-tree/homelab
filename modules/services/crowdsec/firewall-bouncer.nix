# System-manager module
{ config, lib, pkgs, ... }:

let
  apiKeyFile = config.homelab.services.crowdsec.firewallBouncer.apiKeyFile;

  runtimeDir = "crowdsec-firewall-bouncer";
  configFile = "/run/${runtimeDir}/config.yaml";

  # JSON is also valid YAML. Only non-secret values enter the store.
  baseConfig = pkgs.writeText "crowdsec-firewall-bouncer-base.json"
    (builtins.toJSON {
      mode = "nftables";

      api_url = "http://127.0.0.1:50120/"; # exposed crowdsec LAPI port
      update_frequency = "10s";

      log_mode = "stdout";
      log_level = "info";
      deny_action = "DROP";

      nftables = {
        ipv4 = {
          enabled = true;
          set-only = false;
          table = "crowdsec";
          chain = "crowdsec-chain";
        };

        ipv6 = {
          enabled = true;
          set-only = false;
          table = "crowdsec6";
          chain = "crowdsec6-chain";
        };
      };
    });

  renderConfig = pkgs.writeShellScript "render-firewall-bouncer-config" ''
    exec ${pkgs.python3}/bin/python3 - <<'PY'
    import json
    import os
    from pathlib import Path

    config = json.loads(Path("${baseConfig}").read_text())

    credential = (
        Path(os.environ["CREDENTIALS_DIRECTORY"]) / "api-key"
    ).read_text().strip()

    if not credential:
        raise SystemExit("CrowdSec firewall bouncer API key is empty")

    config["api_key"] = credential

    os.umask(0o077)
    Path("${configFile}").write_text(json.dumps(config))
    PY
  '';
in lib.mkIf (config.homelab.services.crowdsec.enable)
# in lib.mkIf (false)
{
  environment.systemPackages = [
    pkgs.crowdsec-firewall-bouncer
    pkgs.nftables
  ];


  systemd.services.crowdsec-firewall-bouncer = {
    description = "CrowdSec host firewall bouncer";

    wantedBy = [ "system-manager.target" ];

    wants = [ "network-online.target" ];
    after = [
      "network-online.target"
      "nftables.service"
    ];

    serviceConfig = {
      Type = "simple";
      User = "root";
      Group = "root";

      LoadCredential = [
        "api-key:${apiKeyFile}"
      ];

      RuntimeDirectory = runtimeDir;
      RuntimeDirectoryMode = "0700";
      UMask = "0077";

      ExecStartPre = "${renderConfig}";
      ExecStart =
        "${pkgs.crowdsec-firewall-bouncer}/bin/cs-firewall-bouncer"
        + " -c ${configFile}";

      Restart = "on-failure";
      RestartSec = "10s";

      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;

      # Do not enable PrivateNetwork: this service must operate
      # in the host network namespace.
    };
  };
}
