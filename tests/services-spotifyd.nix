{ config, lib, pkgs, ... }:

with lib;

let
  spotifyd = pkgs.runCommand "spotifyd-0.0.0" {} "mkdir $out";
in

{
  services.spotifyd.enable = true;
  services.spotifyd.package = spotifyd;

  test = ''
    echo >&2 "checking spotifyd service in ~/Library/LaunchAgents"
    grep "org.nixos.spotifyd" ${config.out}/user/Library/LaunchAgents/org.nixos.spotifyd.plist
    grep "${spotifyd}/bin/spotifyd" ${config.out}/user/Library/LaunchAgents/org.nixos.spotifyd.plist
  '';
}
