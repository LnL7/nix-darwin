{ config, pkgs, ... }:

let
  nix = pkgs.runCommand "nix-0.0.0" {} "mkdir -p $out";
in

{
  nix.gc.automatic = true;
  nix.package = nix;

  test = ''
    echo checking nix-gc validation >&2
    grep "nix.gc.user = " ${config.out}/activate-user

    echo checking nix-gc service in /Library/LaunchDaemons >&2
    grep "<string>org.nixos.nix-gc</string>" ${config.out}/Library/LaunchDaemons/org.nixos.nix-gc.plist
    ! grep "<key>UserName</key>" ${config.out}/Library/LaunchDaemons/org.nixos.nix-gc.plist
  '';
}
