# Radicale

## Adding new user

Users are managed via encrypted generated htpasswd entries within nix
and attached as volume to the podman container.

To add a new user, do:

1. Create password backed with bcrypt: `nix shell 'nixpkgs#apacheHttpd' -c htpasswd -nB <username>`. Enter the password.
2. Place generated with `htpasswd` entry to the `homelab.secrets` `radicale/users` key with sops.
