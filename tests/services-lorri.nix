{ config, pkgs, ... }:

{
  services.lorri.enable = true;

  test = ''
    echo >&2 "checking lorri service in ~/Library/LaunchAgents"
    grep "org.nixos.lorri" ${config.out}/user/Library/LaunchAgents/org.nixos.lorri.plist
    grep "${pkgs.lorri}/bin/lorri" ${config.out}/user/Library/LaunchAgents/org.nixos.lorri.plist
  '';
}
