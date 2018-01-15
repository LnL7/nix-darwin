{ stdenv, nix, pkgs }:

let
  nixPath = stdenv.lib.concatStringsSep ":" [
    "darwin-config=${toString ./configuration.nix}"
    "darwin=${toString ../..}"
    "nixpkgs=${toString pkgs.path}"
    "$NIX_PATH"
  ];
in

stdenv.mkDerivation {
  name = "darwin-installer";

  unpackPhase = ":";

  installPhase = ''
    mkdir -p $out/bin
    echo "$shellHook" > $out/bin/darwin-installer
    chmod +x $out/bin/darwin-installer
  '';

  shellHook = ''
    #!/usr/bin/env bash
    set -e

    action=switch
    while [ "$#" -gt 0 ]; do
        i="$1"; shift 1
        case "$i" in
            --help)
                echo "darwin-installer: [--help] [--check]"
                exit
                ;;
            --check)
                action=check
                ;;
        esac
    done

    export nix=${nix}

    config=$(nix-instantiate --eval -E '<darwin-config>' 2> /dev/null || echo "$HOME/.nixpkgs/darwin-configuration.nix")
    if ! test -f "$config"; then
        echo "copying example configuration.nix" >&2
        mkdir -p "$HOME/.nixpkgs"
        cp "${toString ../../modules/examples/simple.nix}" "$config"
    fi

    # Skip when stdin is not a tty, eg.
    # $ yes | darwin-installer
    if test -t 0; then
        read -p "Would you like edit the default configuration.nix before starting? [y/n] " i
        case "$i" in
            y|Y)
                $EDITOR "$config"
                ;;
        esac
    fi

    export NIX_PATH=${nixPath}
    system=$($nix/bin/nix-build '<darwin>' -I "user-darwin-config=$config" -A system --no-out-link)
    export PATH=$system/sw/bin:$PATH

    darwin-rebuild "$action" -I "user-darwin-config=$config"

    echo >&2
    echo >&2 "    Open '$config' to get started."
    echo >&2 "    See the README for more information: [0;34mhttps://github.com/LnL7/nix-darwin/blob/master/README.md[0m"
    echo >&2
    echo >&2 "    Don't forget to start a new shell or source /etc/static/bashrc."
    echo >&2
    exit
  '';
}
