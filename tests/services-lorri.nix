{ config, pkgs, ... }:

let
  nix = pkgs.runCommand "nix-0.0.0" { version = "1.11.6"; } "mkdir -p $out";
  plistPath = "${config.out}/user/Library/LaunchAgents/org.nixos.lorri.plist";
in
{
  services.lorri.enable = true;
  nix.package = nix;

  test = ''
    echo checking lorri service in /Library/LaunchAgents >&2
    cat ${plistPath}
    grep -o "<key>KeepAlive</key>" ${plistPath}
    grep -o "<string>org.nixos.lorri</string>" ${plistPath}
    grep -o "<string>exec ${pkgs.lorri}/bin/lorri daemon</string>" ${plistPath}
  '';
}
