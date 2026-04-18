# xray

This configuration includes XTLS Reality.

## Setup

### Server

1. Put `template.config.json` into `config/xray/config.json`
2. Generate private/public keys for reality: `xray x25519 [-i "(base64.RawURLEncoding)" --std-encoding]`
3. For fallback service, add handling url in traefik: `Host(`${XRAY_MASKING_SUBDOMAIN}.${DOMAIN_NAME}`) # for masking service with xray`

User configuration:

1. Generate uuid: `xray uuid`.
2. Generate short user id: `openssl rand -hex 8`.

short id index in array should be the same for client configuration. An example:

```json
"clients": [
    {
        "email": "<user1>",
        "flow": "xtls-rprx-vision",
        "id": "<user1-uuid>"
    },
    {
        "email": "<user2>",
        "flow": "xtls-rprx-vision",
        "id": "<user2-uuid>"
    }
]

"shortIds": [
    "<user1-shortId>",
    "<user2-shortId>"
]
```

### Client

#### Subscriptions URL

Recommended for dynamic environments - when configurations, protocols, servers, etc could change.
Works via hosting static text file accessible via special URL. In the client app, the user should paste URL to this file.
Client updates profiles configuration via provided link automatically.

Some implementation notes:

Traefik serves certificate and HTTPS connection at `${XRAY_SUBSCRIPTIONS_SUBDOMAIN}.${DOMAIN_NAME}`.
It also terminates TLS connection and redirects http traffic to nginx statically served location.

Nginx hides subscriptions access behind `${XRAY_SUBSCRIPTIONS_URL_SUBPATH}` path.
As other protection mean, it enables http basic auth for files access.
Every user should have their own credentials to access their own subscriptions.

Where subscriptions are hosted: `${HOSTED_SERVICES_DATA_PATH}/xray/subscriptions`. In this directory, the structure:

```text
${HOSTED_SERVICES_DATA_PATH}/xray/subscriptions
├── auth
│   └── users.htpasswd # <- http basic auth credentials
└── configs
    └── <user-specific-subscription>.txt <- Randomly generated string of length 40. Stores subscriptions of the specific user. Mapping between this file name and a user it corresponds to - is managed out of scope of this repo. Store this corresponding somewhere
```

Actual correspondence of subscriptions and users:

For every user of xray:

1. Create unique client configuration in json with unique id and short-id.
2. Create http basic auth credentials for this user: `sudo htpasswd -c ${HOSTED_SERVICES_DATA_PATH}/xray/subscriptions/auth/users.htpasswd <user-name>`.
3. Create file with subscriptions and insert profile links: `nvim ${HOSTED_SERVICES_DATA_PATH}/xray/subscriptions/configs/$(openssl rand 32 | basenc --base64url | tr -d '=').txt`.

Provide subscription URL to the user in format: `https://<base-auth-name>:<base-auth-password>@${XRAY_SUBSCRIPTIONS_SUBDOMAIN}.${DOMAIN_NAME}/${XRAY_SUBSCRIPTIONS_URL_SUBPATH}/<path to generated subscription file>`.

#### Direct profile link

Use the following setup link template:

`vless://<UUID>@<server host>?security=reality&encryption=none&pbk=<public key>&headerType=none&fp=chrome&spx=%2F&type=tcp&flow=xtls-rprx-vision&sni=<SNI domain>&sid=<short ID>#connection`

## Test

Run:
`curl -v --resolve <SNI domain>:443:<server IP> https://<SNI domain>`.
Expected result: response from masked service behind SNI.

## Utils

Generate random bytes with `openssl`: `openssl rand 32` (32 bytes).

Encode stdin string with url-safe base64 format (still have `=` paddings): `basenc --base64url`.

Remove `=` padding in base64 encoded values in stdin: `tr -d '='`.
