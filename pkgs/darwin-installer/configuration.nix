{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ <user-darwin-config> ];

  users.nix.configureBuildUsers = true;
  users.knownGroups = [ "nixbld" ];

  system.activationScripts.preUserActivation.text = mkBefore ''
    PATH=/nix/var/nix/profiles/default/bin:$PATH

    i=y
    if ! test -L /etc/bashrc && ! tail -n1 /etc/bashrc | grep -q /etc/static/bashrc; then
        if test -t 1; then
            read -p "Would you like to load darwin configuration in /etc/bashrc? [y/n] " i
        fi
        case "$i" in
            y|Y)
                sudo ${pkgs.gnused}/bin/sed -i '\,/etc/static/bashrc,d' /etc/bashrc
                echo 'if test -e /etc/static/bashrc; then . /etc/static/bashrc; fi' | sudo tee -a /etc/bashrc
                ;;
        esac
    fi

    if ! test -L /etc/zshrc && ! tail -n1 /etc/zshrc | grep -q /etc/static/zshrc; then
        if test -t 1; then
            read -p "Would you like to load darwin configuration in /etc/zshrc? [y/n] " i
        fi
        case "$i" in
            y|Y)
                sudo ${pkgs.gnused}/bin/sed -i '\,/etc/static/zshrc,d' /etc/zshrc
                echo 'if test -e /etc/static/zshrc; then . /etc/static/zshrc; fi' | sudo tee -a /etc/zshrc
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
                  /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -B &>/dev/null \
                      || /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t &>/dev/null \
                      || echo "warning: failed to execute apfs.util"
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
