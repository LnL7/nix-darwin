{ config, pkgs, ... }:

let
  cacert = pkgs.runCommand "cacert-0.0.0" {} "mkdir -p $out";
  nix = pkgs.runCommand "nix-0.0.0" { version = "1.11.6"; } "mkdir -p $out";
in

{
  services.nix-daemon.enable = true;
  nix.package = nix;

  environment.variables.NIX_SSL_CERT_FILE = "${cacert}/etc/ssl/certs/ca-certificates.crt";

  test = ''
    echo checking nix-daemon service in /Library/LaunchDaemons >&2
    grep "<string>org.nixos.nix-daemon</string>" ${config.out}/Library/LaunchDaemons/org.nixos.nix-daemon.plist
    grep "<string>/bin/wait4path" ${config.out}/Library/LaunchDaemons/org.nixos.nix-daemon.plist
    grep "&amp;&amp;" ${config.out}/Library/LaunchDaemons/org.nixos.nix-daemon.plist
    grep "exec ${nix}/bin/nix-daemon</string>" ${config.out}/Library/LaunchDaemons/org.nixos.nix-daemon.plist
    grep "<key>KeepAlive</key>" ${config.out}/Library/LaunchDaemons/org.nixos.nix-daemon.plist
    ! grep "<key>Sockets</key>" ${config.out}/Library/LaunchDaemons/org.nixos.nix-daemon.plist

    echo checking NIX_SSL_CERT_FILE in nix-daemon service >&2
    grep "<key>NIX_SSL_CERT_FILE</key>" ${config.out}/Library/LaunchDaemons/org.nixos.nix-daemon.plist
    grep "<string>${cacert}/etc/ssl/certs/ca-certificates.crt</string>" ${config.out}/Library/LaunchDaemons/org.nixos.nix-daemon.plist

    echo checking nix-daemon reload in /activate >&2
    grep "pkill -HUP nix-daemon" ${config.out}/activate

    echo checking NIX_REMOTE=daemon in setEnvironment >&2
    grep "NIX_REMOTE=daemon" ${config.system.build.setEnvironment}
  '';
}
