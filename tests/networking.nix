{ config, pkgs, ... }:

{
  networking.hostName = "EVE";

  test = ''
    echo checking hostname in /activate >&2
    grep "scutil --set ComputerName 'EVE'" ${config.out}/activate
    grep "scutil --set LocalHostName 'EVE'" ${config.out}/activate
    grep "scutil --set HostName 'EVE'" ${config.out}/activate
    echo checking defaults write in ${config.out}/activate-user >&2
    grep "defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server 'NetBIOSName' -string 'EVE'" ${config.out}/activate-user
  '';
}
