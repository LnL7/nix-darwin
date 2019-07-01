{ stdenv, writeScript, nix, pkgs }:

let
  nixPath = stdenv.lib.concatStringsSep ":" [
    "darwin-config=${toString ./configuration.nix}"
    "darwin=${toString ../..}"
    "nixpkgs=${toString pkgs.path}"
    "$HOME/.nix-defexpr/channels"
    "/nix/var/nix/profiles/per-user/root/channels"
    "$NIX_PATH"
  ];
in

stdenv.mkDerivation {
  name = "darwin-installer";
  preferLocalBuild = true;

  unpackPhase = ":";

  installPhase = ''
    mkdir -p $out/bin
    echo "$shellHook" > $out/bin/darwin-installer
    chmod +x $out/bin/darwin-installer
  '';

  shellHook = ''
    set -e

    _PATH=$PATH
    export PATH=/nix/var/nix/profiles/default/bin:${nix}/bin:${pkgs.gnused}/bin:${pkgs.openssh}/bin:/usr/bin:/bin:/usr/sbin:/sbin

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

    echo >&2
    echo >&2 "Installing nix-darwin..."
    echo >&2

    config=$(nix-instantiate --eval -E '<darwin-config>' 2> /dev/null || echo "$HOME/.nixpkgs/darwin-configuration.nix")
    if ! test -f "$config"; then
        echo "copying example configuration.nix" >&2
        mkdir -p "$HOME/.nixpkgs"
        cp "${toString ../../modules/examples/simple.nix}" "$config"
        chmod u+w "$config"
    fi

    # Enable nix-daemon service for multi-user installs.
    if [ ! -w /nix/var/nix/db ]; then
        sed -i 's/# services.nix-daemon.enable/services.nix-daemon.enable/' "$config"
    fi

    # Skip when stdin is not a tty, eg.
    # $ yes | darwin-installer
    if test -t 0; then
        read -p "Would you like edit the default configuration.nix before starting? [y/n] " i
        case "$i" in
            y|Y)
                PATH=$_PATH ''${EDITOR:-nano} "$config"
                ;;
        esac
    fi

    export NIX_PATH=${nixPath}
    system=$(nix-build '<darwin>' -I "user-darwin-config=$config" -A system --no-out-link --show-trace)

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

  passthru.check = stdenv.mkDerivation {
     name = "run-darwin-test";
     shellHook = ''
        set -e
        echo >&2 "running installer tests..."
        echo >&2

        echo >&2 "checking configuration.nix"
        test -f ~/.nixpkgs/darwin-configuration.nix
        test -w ~/.nixpkgs/darwin-configuration.nix
        echo >&2 "checking darwin channel"
        readlink ~/.nix-defexpr/channels/darwin
        test -e ~/.nix-defexpr/channels/darwin
        echo >&2 "checking /etc"
        readlink /etc/static
        test -e /etc/static
        grep /etc/static/bashrc /etc/bashrc
        grep -v nix-daemon.sh /etc/profile
        echo >&2 "checking /run/current-system"
        readlink /run
        test -e /run
        readlink /run/current-system
        test -e /run/current-system
        echo >&2 "checking profile"
        readlink /nix/var/nix/profiles/system
        test -e /nix/var/nix/profiles/system
        echo >&2 ok
        exit
    '';
  };
}
