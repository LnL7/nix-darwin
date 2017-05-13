{ config, pkgs, ... }:

{
  system.defaults.NSGlobalDomain.KeyRepeat = 1;
  system.defaults.dock.orientation = "left";

  test = ''
    echo checking defaults write in /activate-user >&2
    grep "defaults write -g 'KeyRepeat' -int 1" ${config.out}/activate-user
    grep "defaults write com.apple.dock 'orientation' -string 'left'" ${config.out}/activate-user
  '';
}
