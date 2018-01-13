{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ <user-darwin-config> ];

  system.activationScripts.preUserActivation.text = mkBefore ''
    darwinPath=$(NIX_PATH=${concatStringsSep ":" config.nix.nixPath} nix-instantiate --eval -E '<darwin>' 2> /dev/null) || true
    if ! test -e "$darwinPath"; then
        if test -t 1; then
            read -p "Would you like to manage <darwin> with nix-channel? [y/n] " i
        fi
        case "$i" in
            y|Y)
                nix-channel --add https://github.com/LnL7/nix-darwin/archive/master.tar.gz darwin
                nix-channel --update
                ;;
        esac
    fi

    if ! test -L /etc/bashrc && ! grep -q /etc/static/bashrc /etc/bashrc; then
        if test -t 1; then
            read -p "Would you like to load darwin configuration in /etc/bashrc? [y/n] " i
        fi
        case "$i" in
            y|Y)
                echo 'if test -e /etc/static/bashrc; then . /etc/static/bashrc; fi' | sudo tee -a /etc/bashrc
                ;;
        esac
    fi

    if ! test -L /etc/profile && grep -q 'etc/profile.d/nix-daemon.sh' /etc/profile; then
        if test -t 1; then
            read -p "Would you like to remove nix-daemon.sh configuration in /etc/profile? [y/n] " i
        fi
        case "$i" in
            y|Y)
                sudo patch -d /etc -p1 < '${./profile.patch}'
                ;;
        esac
    fi
  '';

  system.activationScripts.preActivation.text = ''
    echo "setting up /run..."
    if ! test -L /run; then
      sudo ln -sfn private/var/run /run
    fi
  '';
}
