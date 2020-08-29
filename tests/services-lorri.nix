{ config, pkgs, ... }:

let
  nix = pkgs.runCommand "nix-0.0.0" { version = "1.11.6"; } "mkdir -p $out";
  plistPath = "${config.out}/user/Library/LaunchAgents/com.target.lorri.plist";
in
{
  services.lorri.enable = true;
  nix.package = pkgs.nix;

  test = ''
    echo checking lorri service in /Library/LaunchAgents >&2
    grep -o "<key>KeepAlive</key>" ${plistPath}
    grep -o "<key>RunAtLoad</key>" ${plistPath}
    grep -o "<key>ProcessType</key>" ${plistPath}
    grep -o "<string>Background</string>" ${plistPath}
    grep -o "<string>com.target.lorri</string>" ${plistPath}
    grep -o "<string>${pkgs.zsh}/bin/zsh</string>" ${plistPath}
    grep -o "<string>-c</string>" ${plistPath}
    grep -o "<string>${pkgs.lorri}/bin/lorri daemon</string>" ${plistPath}
  '';
}
