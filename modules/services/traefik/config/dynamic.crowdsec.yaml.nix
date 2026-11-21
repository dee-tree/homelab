{ lib, cfg }:

''
  http:
    middlewares:
      crowdsec:
        plugin:
          bouncer:
            enabled: true
            logLevel: ERROR
            LogFilePath: /var/log/traefik/crowdsec.log
            crowsecMode: stream
            crowdsecAppsecEnabled: true
            CrowdsecAppsecScheme: http
            crowdsecAppsecHost: crowdsec:7422
            crowdsecAppsecFailureBlock: true
            crowdsecAppsecUnreachableBlock: true
            crowdsecLapiKeyFile: /run/traefik/secrets/crowdsec-bouncer-key
            crowdsecLapiScheme: http
            crowdsecLapiHost: crowdsec:8080
            crowdsecLapiPath: /
            forwardedHeadersTrustedIPs:
              - 10.90.0.0/12
              - 10.90.0.10/32 # nginx
              - 10.90.0.11/32 # xray
              - 10.90.0.12/32
            clientTrustedIPs:
              - 10.90.0.10/32 # nginx
              - 10.90.0.11/32 # xray

              # - {{ env "TRUSTED_IP1" }}
              # - {{ env "TRUSTED_IP2" }}
''
