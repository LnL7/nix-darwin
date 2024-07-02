{ config, pkgs, ... }:

let
  settings = {
    enable = true;
    periodSeconds = 10;
  };
in

{
  nix.optimise = settings;

  test = ''
    plist=${config.out}/Library/LaunchDaemons/org.nixos.nix-optimise.plist
    test -f $plist
    content=$(tr -d '\n\t ' < $plist)

    echo "$content" | grep '<array><string>/nix/store/.*/bin/nix-store</string><string>--optimise</string></array>'
    echo "$content" | grep '<key>StartInterval</key><integer>${settings.periodSeconds}</integer>'
  '';
}
