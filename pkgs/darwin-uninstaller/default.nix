{ stdenv, nix, pkgs, nix-darwin }:

let
  configuration = builtins.path {
    name = "nix-darwin-uninstaller-configuration";
    path = ./.;
    filter = name: _type: name != toString ./default.nix;
  };

  nixPath = stdenv.lib.concatStringsSep ":" [
    "darwin-config=${configuration}/configuration.nix"
    "darwin=${nix-darwin}"
    "nixpkgs=${pkgs.path}"
    "$NIX_PATH"
  ];
in

stdenv.mkDerivation {
  name = "darwin-uninstaller";
  preferLocalBuild = true;

  unpackPhase = ":";

  installPhase = ''
    mkdir -p $out/bin
    echo "$shellHook" > $out/bin/darwin-uninstaller
    chmod +x $out/bin/darwin-uninstaller
  '';

  shellHook = ''
    #!${stdenv.shell}
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
    echo >&2 "    - remove ~/Applications link."
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
      sudo rm /run/current-system
    fi

    echo >&2
    echo >&2 "NOTE: The /nix/var/nix/profiles/system* profiles still exist and won't be garbage collected."
    echo >&2
    echo >&2 "Done!"
    echo >&2
    exit
  '';

  passthru.check = stdenv.mkDerivation {
     name = "run-darwin-test";
     shellHook = ''
        set -e
        echo >&2 "running uninstaller tests..."
        echo >&2

        echo >&2 "checking darwin channel"
        ! test -e ~/.nix-defexpr/channels/darwin
        echo >&2 "checking /etc"
        ! test -e /etc/static
        echo >&2 "checking /run/current-system"
        ! test -e /run/current-system
        echo >&2 "checking nix-daemon service (assuming a multi-user install)"
        sudo launchctl list | grep org.nixos.nix-daemon || echo "FIXME? sudo launchctl list | grep org.nixos.nix-daemon"
        pgrep -l nix-daemon || echo "FIXME? pgrep -l nix-daemon"
        readlink /Library/LaunchDaemons/org.nixos.nix-daemon.plist || echo "FIXME? readlink /Library/LaunchDaemons/org.nixos.nix-daemon.plist"
        grep /nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt /Library/LaunchDaemons/org.nixos.nix-daemon.plist || echo "FIXME? grep /nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt /Library/LaunchDaemons/org.nixos.nix-daemon.plist"
        echo >&2 ok
        exit
    '';
  };
}
