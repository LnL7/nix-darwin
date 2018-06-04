{ config, lib, pkgs, ... }:

with lib;

let
  dovecot = pkgs.runCommand "dovecot-0.0.0" {} "mkdir $out";
in

{
  services.dovecot.enable = true;
  services.dovecot.package = dovecot;

  services.dovecot.extraConfig = ''
  '';

  test = ''
    echo >&2 "checking dovecot service in ~/Library/LaunchAgents"
    grep "org.nixos.dovecot" ${config.out}/user/Library/LaunchAgents/org.nixos.dovecot.plist
    grep "${dovecot}/bin/dovecot" ${config.out}/user/Library/LaunchAgents/org.nixos.dovecot.plist

    echo >&2 "checking config in /etc/dovecot/dovecot.conf"
    grep "accounts = test" ${config.out}/etc/dovecot/dovecot.conf
  '';
}
