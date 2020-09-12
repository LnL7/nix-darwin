{ config, pkgs, ... }:

{
  networking.hostName = "EVE";
  networking.computerName = "EVE’s MacBook Pro";

  test = ''
    echo checking hostname in /activate >&2
    grep "scutil --set ComputerName 'EVE’s MacBook Pro'" ${config.out}/activate
    grep "scutil --set LocalHostName 'EVE'" ${config.out}/activate
    grep "scutil --set HostName 'EVE'" ${config.out}/activate
    echo checking defaults write in ${config.out}/activate-user >&2
  '';
}
