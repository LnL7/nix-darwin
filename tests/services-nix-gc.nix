{ config, pkgs, ... }:

let
  nix = pkgs.runCommand "nix-0.0.0" {} "mkdir -p $out";
in

{
  nix.gc.automatic = true;
  nix.gc.options = "--delete-older-than 30d";
  nix.gc.user = "nixuser";
  nix.package = nix;

  test = ''
    echo checking nix-gc service in /Library/LaunchDaemons >&2
    grep "<string>org.nixos.nix-gc</string>" ${config.out}/Library/LaunchDaemons/org.nixos.nix-gc.plist
    grep "<string>exec ${nix}/bin/nix-collect-garbage --delete-older-than 30d</string>" ${config.out}/Library/LaunchDaemons/org.nixos.nix-gc.plist
    grep "<key>UserName</key>" ${config.out}/Library/LaunchDaemons/org.nixos.nix-gc.plist
    ! grep "<string>nixuser</string>" ${config.out}/Library/LaunchDaemons/org.nixos.nix-gc.plist

    ! grep "<key>KeepAlive</key>" ${config.out}/Library/LaunchDaemons/org.nixos.nix-gc.plist

    echo checking nix-gc validation >&2
    ! grep "nix.gc.user = " ${config.out}/activate-user
  '';
}
