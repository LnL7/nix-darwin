{ config, lib, pkgs, ... }:

with lib;

{
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
  '';
}
