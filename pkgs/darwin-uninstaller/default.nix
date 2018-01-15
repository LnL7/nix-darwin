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
          echo "darwin-uninstaller: [--check]"
          exit
          ;;
        --check)
          action=check
          ;;
      esac
    done

    export nix=${nix}
    export NIX_PATH=${nixPath}
    system=$($nix/bin/nix-build '<darwin>' -A system)
    $system/sw/bin/darwin-rebuild switch

    echo >&2
    echo >&2 "Done!"
    echo >&2
    exit
  '';
}
