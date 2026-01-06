# xray

This configuration includes XTLS Reality.

## Setup

### Server

1. Put `template.config.json` into `config/xray/config.json`
2. Generate uuid: `xray uuid`
3. Generate private/public keys for reality: `xray x25519 [-i "(base64.RawURLEncoding)" --std-encoding]`
4. Generate short user id: `openssl rand -hex 8`

### Client

Use the following setup link template:

`vless://<UUID>@<server host>?security=reality&encryption=none&pbk=<public key>&headerType=none&fp=chrome&spx=%2F&type=tcp&flow=xtls-rprx-vision&sni=<SNI domain>&sid=<short ID>#connection`
