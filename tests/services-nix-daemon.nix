{ config, pkgs, ... }:

let
  nix = pkgs.runCommand "nix-0.0.0" { version = "1.11.6"; } "mkdir -p $out";
in

{
  services.nix-daemon.enable = true;
  nix.package = nix;

  programs.zsh.enable = true;

  test = ''
    echo checking nix-daemon service in /Library/LaunchDaemons >&2
    grep "<string>org.nixos.nix-daemon</string>" ${config.out}/Library/LaunchDaemons/org.nixos.nix-daemon.plist
    grep "<string>exec ${nix}/bin/nix-daemon</string>" ${config.out}/Library/LaunchDaemons/org.nixos.nix-daemon.plist
    grep "<key>KeepAlive</key>" ${config.out}/Library/LaunchDaemons/org.nixos.nix-daemon.plist
    ! grep "<key>Sockets</key>" ${config.out}/Library/LaunchDaemons/org.nixos.nix-daemon.plist

    echo checking nix-daemon reload in /activate >&2
    grep "pkill -HUP nix-daemon" ${config.out}/activate

    echo checking NIX_REMOTE=daemon in /etc/bashrc >&2
    grep "NIX_REMOTE=daemon" ${config.out}/etc/bashrc
    echo "checking NIX_REMOTE=daemon in /etc/zshenv" >&2
    grep 'export NIX_REMOTE=daemon' ${config.out}/etc/zshenv
  '';
}
