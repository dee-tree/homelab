# Crowdsec

Crowdsec is running as a podman container.
It has the following integrations installed:

- system-level firewall bouncer
- traefik bouncer

For its bouncers, API keys should be generated.

To do it, invoke API key generation command within podman `crowdsec`:

```sh
# enter podman container shell with:
# podman exec -it crowdsec sh

# Get traefik bouncer API key:
cscli bouncers add traefik-bouncer-<hostname>

# Get firewall bouncer API key:
cscli bouncers add host-firewall-bouncer-<hostname>
```

After keys generation, set `crowdsec/traefik_bouncer_api_key` and `crowdsec/traefik_bouncer_api_key` keys with sops in `homelab.secrets`

TODO: Consider automating bouncer API key generation.
