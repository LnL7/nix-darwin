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
          echo "darwin-installer: [--check]"
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

    export NIX_PATH=${nixPath}
    system=$($nix/bin/nix-build '<darwin>' -I "user-darwin-config=$config" -A system --no-out-link)
    export PATH=$system/sw/bin:$PATH

    darwin-rebuild "$action" -I "user-darwin-config=$config"

    echo >&2
    echo "    Open '$config' to get started." >&2
    echo "    See the README for more information: [0;34mhttps://github.com/LnL7/nix-darwin/blob/master/README.md[0m" >&2
    echo >&2
    echo "    Don't forget to start a new shell or source /etc/static/bashrc." >&2
    echo >&2
    exit
  '';
}
