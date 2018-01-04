{ config, pkgs, ... }:

{
  networking.hostName = "EVE";

  test = ''
    echo checking hostname write in /activate >&2
    grep 'scutil --set ComputerName "EVE"' ${config.out}/activate
    grep 'scutil --set LocalHostName "EVE"' ${config.out}/activate
    grep 'scutil --set HostName "EVE"' ${config.out}/activate
    grep "defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string 'EVE'" ${config.out}/activate
  '';
}
