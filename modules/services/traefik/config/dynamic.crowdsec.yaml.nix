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
            crowdsecAppsecHost: crowdsec:7422
            crowdsecAppsecFailureBlock: true
            crowdsecAppsecUnreachableBlock: true
            # crowdsecLapiKey: {{ env "CROWDSEC_TRAEFIK_LAPI_KEY" }}
            crowdsecLapiKeyFile: /run/traefik/secrets/crowdsec-bouncer-key
            crowdsecLapiHost: crowdsec:8080
            crowdsecLapiPath: /
            forwardedHeadersTrustedIPs:
              # - 10.0.35.4/32
              # - 192.168.0.0/16
              # - 10.0.0.0/8
              - 10.90.0.0/12
              - 10.90.0.10/32
              - 10.90.0.11/32
              - 10.90.0.12/32
            clientTrustedIPs:
              # - {{ env "TRUSTED_IP1" }}
              # - {{ env "TRUSTED_IP2" }}

''
