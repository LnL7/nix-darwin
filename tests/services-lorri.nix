{ config, pkgs, ... }:

let
  lorri = pkgs.runCommand "lorri-0.0.0" {} "mkdir $out";
  plistPath = "${config.out}/user/Library/LaunchAgents/org.nixos.lorri.plist";
in
{
  services.lorri.enable = true;

  test = ''
    echo checking lorri service in /Library/LaunchAgents >&2
    grep -o "<key>NIX_PATH</key>" ${plistPath}
    grep -o "<key>EnvironmentVariables</key>" ${plistPath}
    grep -o "<string>nixpkgs=" ${plistPath}
    grep -o "<key>KeepAlive</key>" ${plistPath}
    grep -o "<key>RunAtLoad</key>" ${plistPath}
    grep -o "<key>ProcessType</key>" ${plistPath}
    grep -o "<string>Background</string>" ${plistPath}
    grep -o "<string>/bin/sh</string>" ${plistPath}
    grep -o "<string>org.nixos.lorri</string>" ${plistPath}
    grep -o "<string>-c</string>" ${plistPath}
    grep -o "<string>exec ${pkgs.lorri}/bin/lorri daemon</string>" ${plistPath}
  '';
}
