{ config, pkgs, ... }:

let
  aerospace = pkgs.runCommand "aerospace-0.0.0" { } "mkdir $out";
in

{
  services.aerospace.enable = true;
  services.aerospace.package = aerospace;
  services.aerospace.settings = {
    after-startup-command = [ "layout tiles" ];
    gaps = {
      outer.left = 8;
      outer.bottom = 8;
      outer.top = 8;
      outer.right = 8;
    };
    mode.main.binding = {
      alt-h = "focus left";
      alt-j = "focus down";
      alt-k = "focus up";
      alt-l = "focus right";
    };
  };

  test = ''
    echo >&2 "checking aerospace service in ~/Library/LaunchAgents"
    grep "org.nixos.aerospace" ${config.out}/user/Library/LaunchAgents/org.nixos.aerospace.plist
    grep "${aerospace}/Applications/AeroSpace.app/Contents/MacOS/AeroSpace" ${config.out}/user/Library/LaunchAgents/org.nixos.aerospace.plist

    conf=`sed -En 's/^[[:space:]]*<string>.*--config-path (.*)<\/string>$/\1/p' \
      ${config.out}/user/Library/LaunchAgents/org.nixos.aerospace.plist`

    echo >&2 "checking config in $conf"
    grep 'after-startup-command = \["layout tiles"\]' $conf

    grep 'bottom = 8' $conf
    grep 'left = 8' $conf
    grep 'right = 8' $conf
    grep 'top = 8' $conf

    grep 'alt-h = "focus left"' $conf
    grep 'alt-j = "focus down"' $conf
    grep 'alt-k = "focus up"' $conf
    grep 'alt-l = "focus right"' $conf
  '';
}
