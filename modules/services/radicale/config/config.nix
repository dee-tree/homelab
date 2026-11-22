{ lib, cfg }:
let
verbose = cfg.verbose || cfg.services.radicale.verbose;
in
''
[server]
    hosts = 0.0.0.0:80

    [auth]
    type = htpasswd
    htpasswd_filename = /etc/radicale/users
    htpasswd_encryption = bcrypt

    [rights]
    type = owner_only

    [storage]
    filesystem_folder = /var/lib/radicale/collections

    [logging]
    level = ${if verbose then "info" else "error"}
''
