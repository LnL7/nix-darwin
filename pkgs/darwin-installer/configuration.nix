{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ <user-darwin-config> ];

  users.nix.configureBuildUsers = true;
  users.knownGroups = [ "nixbld" ];

  system.activationScripts.preUserActivation.text = mkBefore ''
    PATH=/nix/var/nix/profiles/default/bin:$PATH

    darwinPath=$(NIX_PATH=${concatStringsSep ":" config.nix.nixPath} nix-instantiate --eval -E '<darwin>' 2> /dev/null) || true
    i=y
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

    if ! test -L /etc/zshrc && ! grep -q /etc/static/zshrc /etc/zshrc; then
        if test -t 1; then
            read -p "Would you like to load darwin configuration in /etc/zshrc? [y/n] " i
        fi
        case "$i" in
            y|Y)
                echo 'if test -e /etc/static/zshrc; then . /etc/static/zshrc; fi' | sudo tee -a /etc/zshrc
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
      if test -t 1; then
          read -p "Would you like to create /run? [y/n] " i
      fi
      case "$i" in
          y|Y)
              if ! grep -q '^run\b' /etc/synthetic.conf 2>/dev/null; then
                  echo "setting up /etc/synthetic.conf..."
                  echo -e "run\tprivate/var/run" | sudo tee -a /etc/synthetic.conf >/dev/null
                  /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -B 2>/dev/null || true
              fi
              if ! test -L /run; then
                  echo "setting up /run..."
                  sudo ln -sfn private/var/run /run
              fi
              ;;
      esac
    fi
  '';
}
