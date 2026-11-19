{
  lib,
  cfg,
}: let
  scfg = cfg.services.xray;
  mkClient = name: id: ''
    {
      "email": "${name}",
      "flow": "xtls-rprx-vision",
      "id": "${id}"
    }
  '';

  mkClients =
    lib.concatStringsSep ",\n"
    (lib.zipListsWith
      mkClient
      scfg.userNames
      scfg.userIds);

  escapedShortIds = map (id: "\"${id}\"") scfg.userShortIds;
  mkShortIds = lib.concatStringsSep ",\n" escapedShortIds;

  realityInbound =
    if (scfg.enableRealityInbound)
    then ''
      {
        "tag": "reality-in",
        "port": "443",
        "protocol": "vless",
        "settings": {
          "clients": [
            ${mkClients}
          ],
          "decryption": "none"
        },
        "sniffing": {
          "enabled": true,
          "destOverride": [
            "http",
            "tls",
            "quic"
          ]
        },
        "streamSettings": {
          "network": "raw",
          "security": "reality",
          "realitySettings": {
            "target": "traefik:443", // <- host as redirection target when connection is not reality
            "privateKey": "${scfg.privateKey}", // ${scfg.publicKey}
            "maxTimeDiff": 86400000, // accept only connections with client time in range of 1 day precision (to avoid time difference attack)
            "serverNames": [
              // TLS Certificate SAN names
              "${scfg.maskingSni}"
            ],
            "shortIds": [
              ${mkShortIds}
            ],
            "show": false, // verbose reality logging
            "xver": 1
          },
          "sockopt": {
            "acceptProxyProtocol": true
          }
        }
      }
    ''
    else "";

  inbounds = lib.concatStringsSep ",\n" [realityInbound];
in ''
  {
    "api": {
      "services": [
        "HandlerService",
        "LoggerService",
        "StatsService"
      ],
      "tag": "api"
    },
    "log": {
      "access": "/var/log/xray/access.log",
      "error": "/var/log/xray/error.log",
      "loglevel": "warning"
    },
    "inbounds": [
      ${inbounds}
    ],
    "outbounds": [
      {
        "tag": "direct",
        "protocol": "freedom"
      },
      {
        "tag": "blocked",
        "protocol": "blackhole"
      }
    ],
    "policy": {
      "levels": {
        "0": {
          "handshake": 5, // The handshake time limit when the connection is established, in seconds, the default value is 4, it is recommended to be different from the default value
          "connIdle": 284, // Connection idle time limit in seconds, the default value is 300, it is recommended to be different from the default value
          "statsUserDownlink": true,
          "statsUserUplink": true
        }
      },
      "system": {
        "statsInboundDownlink": true,
        "statsInboundUplink": true,
        "statsOutboundDownlink": true,
        "statsOutboundUplink": true
      }
    }
  }
''
