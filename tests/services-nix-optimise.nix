{ config, pkgs, ... }:

let
  nix = pkgs.runCommand "nix-2.2" {} "mkdir -p $out";
in

{
  nix.optimise.automatic = true;
  nix.optimise.user = "nixuser";
  nix.package = nix;

  test = ''
    echo checking nix-optimise service in /Library/LaunchDaemons >&2
    grep "<string>org.nixos.nix-optimise</string>" \
      ${config.out}/Library/LaunchDaemons/org.nixos.nix-optimise.plist
    grep "<string>/bin/wait4path ${nix} &amp;&amp; exec ${nix}/bin/nix-store --optimise</string>" \
      ${config.out}/Library/LaunchDaemons/org.nixos.nix-optimise.plist
    grep "<key>UserName</key>" ${config.out}/Library/LaunchDaemons/org.nixos.nix-optimise.plist
    grep "<string>nixuser</string>" ${config.out}/Library/LaunchDaemons/org.nixos.nix-optimise.plist
    (! grep "<key>KeepAlive</key>" ${config.out}/Library/LaunchDaemons/org.nixos.nix-optimise.plist)

    echo checking nix-optimise validation >&2
    (! grep "nix.optimise.user = " ${config.out}/activate-user)
  '';
}
