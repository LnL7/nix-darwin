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
  name = "darwin-uninstaller";

  unpackPhase = ":";

  installPhase = ''
    mkdir -p $out/bin
    echo "$shellHook" > $out/bin/darwin-uninstaller
    chmod +x $out/bin/darwin-uninstaller
  '';

  shellHook = ''
    #!/usr/bin/env bash
    set -e

    action=switch
    while [ "$#" -gt 0 ]; do
        i="$1"; shift 1
        case "$i" in
            --help)
                echo "darwin-uninstaller: [--help]"
                exit
                ;;
        esac
    done

    echo >&2
    echo >&2 "Uninstalling nix-darwin, this will:"
    echo >&2
    echo >&2 "    - remove ~/Applications link.
    echo >&2 "    - cleanup static /etc files."
    echo >&2 "    - disable and remove all launchd services managed by nix-darwin."
    echo >&2 "    - restore daemon service from nix installer (only when this is a multi-user install)."
    echo >&2

    if test -t 0; then
        read -p "Proceed? [y/n] " i
        case "$i" in
            y|Y)
                ;;
            *)
                exit 3
                ;;
        esac
    fi

    export nix=${nix}
    export NIX_PATH=${nixPath}
    system=$($nix/bin/nix-build '<darwin>' -A system)
    $system/sw/bin/darwin-rebuild switch

    if test -L /run/current-system; then
      rm /run/current-system
    fi

    echo >&2
    echo >&2 "NOTE: The /nix/var/nix/profiles/system* profiles still exist and won't be garbage collected."
    echo >&2
    echo >&2 "Done!"
    echo >&2
    exit
  '';
}
