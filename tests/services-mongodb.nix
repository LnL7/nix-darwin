{ config, pkgs, ... }:
let mongodb = pkgs.runCommand "mongodb-0.0.0" { } "mkdir $out";
in {
  services.mongodb.enable = true;
  services.mongodb.package = mongodb;

  test = ''
    echo >&2 "checking mongodb service in ~/Library/LaunchAgents"
    grep "org.nixos.mongodb" ${config.out}/user/Library/LaunchAgents/org.nixos.mongodb.plist
    grep "${mongodb}/bin" ${config.out}/user/Library/LaunchAgents/org.nixos.mongodb.plist
    grep "mongodb-start" ${config.out}/user/Library/LaunchAgents/org.nixos.mongodb.plist
  '';
}
