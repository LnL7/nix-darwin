{ stdenv, writeScript, nix, pkgs, nix-darwin }:

let
  configuration = builtins.path {
    name = "nix-darwin-installer-configuration";
    path = ./.;
    filter = name: _type: name != toString ./default.nix;
  };

  nixPath = pkgs.lib.concatStringsSep ":" [
    "darwin-config=${configuration}/configuration.nix"
    "darwin=${nix-darwin}"
    "nixpkgs=${pkgs.path}"
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
    #!${stdenv.shell}
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
        cp "${../../modules/examples/simple.nix}" "$config"
        chmod u+w "$config"

        # Enable nix-daemon service for multi-user installs.
        if [ ! -w /nix/var/nix/db ]; then
            sed -i 's/# services.nix-daemon.enable/services.nix-daemon.enable/' "$config"
        fi
    fi

    # Skip when stdin is not a tty, eg.
    # $ yes | darwin-installer
    if test -t 0; then
        read -p "Would you like to edit the default configuration.nix before starting? [y/n] " i
        case "$i" in
            y|Y)
                PATH=$_PATH ''${EDITOR:-nano} "$config"
                ;;
        esac
    fi

    i=y
    darwinPath=$(NIX_PATH=$HOME/.nix-defexpr/channels nix-instantiate --eval -E '<darwin>' 2> /dev/null) || true
    if ! test -e "$darwinPath"; then
        if test -t 0; then
            read -p "Would you like to manage <darwin> with nix-channel? [y/n] " i
        fi
        case "$i" in
            y|Y)
                nix-channel --add https://github.com/LnL7/nix-darwin/archive/master.tar.gz darwin
                nix-channel --update
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
        echo >&2 "checking /etc/static in bashrc"
        cat /etc/bashrc
        grep /etc/static/bashrc /etc/bashrc
        echo >&2 "checking /etc/static in zshrc"
        cat /etc/zshrc
        grep /etc/static/zshrc /etc/zshrc
        echo >&2 "checking profile"
        cat /etc/profile
        grep -v nix-daemon.sh /etc/profile
        echo >&2 "checking /run/current-system"
        readlink /run
        test -e /run
        readlink /run/current-system
        test -e /run/current-system
        echo >&2 "checking system profile"
        readlink /nix/var/nix/profiles/system
        test -e /nix/var/nix/profiles/system

        echo >&2 "checking bash environment"
        env -i USER=john HOME=/Users/john bash -li -c 'echo $PATH'
        env -i USER=john HOME=/Users/john bash -li -c 'echo $PATH' | grep /Users/john/.nix-profile/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin
        env -i USER=john HOME=/Users/john bash -li -c 'echo $NIX_PATH'
        env -i USER=john HOME=/Users/john bash -li -c 'echo $NIX_PATH' | grep darwin-config=/Users/john/.nixpkgs/darwin-configuration.nix:/nix/var/nix/profiles/per-user/root/channels:/Users/john/.nix-defexpr/channels

        echo >&2 "checking zsh environment"
        env -i USER=john HOME=/Users/john zsh -l -c 'echo $PATH'
        env -i USER=john HOME=/Users/john zsh -l -c 'echo $PATH' | grep /Users/john/.nix-profile/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/default/bin:/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin
        env -i USER=john HOME=/Users/john zsh -l -c 'echo $NIX_PATH' | grep darwin-config=/Users/john/.nixpkgs/darwin-configuration.nix:/nix/var/nix/profiles/per-user/root/channels:/Users/john/.nix-defexpr/channels
        env -i USER=john HOME=/Users/john zsh -l -c 'echo $NIX_PATH'

        echo >&2 ok
        exit
    '';
  };
}
