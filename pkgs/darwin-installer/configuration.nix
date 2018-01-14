{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ <user-darwin-config> ];

  # NOTE: don't set this outside of the instaler.
  users.nix.configureBuildUsers = true;
  users.knownGroups = [ "nixbld" ];
  users.knownUsers = [ "nixbld1" "nixbld2" "nixbld3" "nixbld4" "nixbld5" "nixbld6" "nixbld7" "nixbld8" "nixbld9" "nixbld10" ];

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

    if ! test -L /run; then
      echo "setting up /run..."
      if test -t 1; then
          read -p "Would you like to create /run? [y/n] " i
      fi
      case "$i" in
          y|Y)
              sudo ln -sfn private/var/run /run
              ;;
      esac
    fi
  '';
}
