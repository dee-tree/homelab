{
  nixpkgs,
  flake-utils,
}:
flake-utils.lib.eachDefaultSystem (
  system: let
    pkgs = nixpkgs.legacyPackages.${system};

    initSecretIdentity = pkgs.writeShellApplication {
      name = "init-secret-identity";
      runtimeInputs = with pkgs; [
        age
        coreutils
      ];
      text = ''
        umask 077

        key_file="''${SOPS_AGE_KEY_FILE:-''${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt}"
        key_dir="$(dirname "$key_file")"

        mkdir -p "$key_dir"
        chmod 700 "$key_dir"

        if [ -e "$key_file" ] || [ -L "$key_file" ]; then
        printf 'Keeping existing identity: %s\n' "$key_file"
        else
        age-keygen -o "$key_file"
        printf 'Created identity: %s\n' "$key_file"
        printf 'Back up this private identity securely.\n'
        fi

        printf '\nPublic recipient:\n'
        age-keygen -y "$key_file"
      '';
    };
  in {
    devShells.default = pkgs.mkShellNoCC {
      packages = with pkgs; [
        sops
        age
        jq
        initSecretIdentity
      ];
      shellHook = ''
        export SOPS_AGE_KEY_FILE="''${SOPS_AGE_KEY_FILE:-''${XDG_CONFIG_HOME:-$HOME/.config}/sops/age/keys.txt}"

        if [ ! -f "$SOPS_AGE_KEY_FILE" ]; then
            printf 'No age identity found at: %s\n' \
            "$SOPS_AGE_KEY_FILE"
            printf 'Create or restore your admin identity before decrypting secrets.\n'
        fi
      '';
    };

    apps.sops-init = {
      type = "app";
      program = "${initSecretIdentity}/bin/init-secret-identity";
    };
  }
)
