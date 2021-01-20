{ config, lib, pkgs, ... }:

with lib;

let
  mbsync = pkgs.runCommand "mbsync-0.0.0" {} "mkdir -p $out";
in

{
  services.mbsync.enable = true;
  services.mbsync.package = mbsync;
  services.mbsync.verbose = true;
  services.mbsync.startInterval = 9000;
  services.mbsync.configFile = "/testConfig";
  services.mbsync.postExec = "testPostExec";
  

  test = ''
    conf=`sed -En '/<string>-c/{n; s/\s+?<\/?string>//g; s/\s+?exec //g; p;}' \
      ${config.out}/user/Library/LaunchAgents/org.nixos.mbsync.plist`

    echo >&2 "checking mbsync service in ~/Library/LaunchAgents"
    grep "org.nixos.mbsync" ${config.out}/user/Library/LaunchAgents/org.nixos.mbsync.plist
    grep "9000" ${config.out}/user/Library/LaunchAgents/org.nixos.mbsync.plist

    echo >&2 "checking config in $conf"
    grep "bin/mbsync" $conf
    grep "\--verbose" $conf
    grep "testConfig" $conf
    grep "testPostExec" $conf
  '';
}
