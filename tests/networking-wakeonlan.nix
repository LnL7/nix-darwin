{ config, pkgs, ... }:

{
  networking.wakeOnLan.enable = true;

  test = ''
    echo checking wake on network access settings in /activate >&2
    grep "systemsetup -setWakeOnNetworkAccess 'on'" ${config.out}/activate
  '';
}
