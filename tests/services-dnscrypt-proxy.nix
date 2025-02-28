{
  config,
  pkgs,
  ...
}:

let
  dnscrypt-proxy = pkgs.runCommand "dnscrypt-proxy-0.0.0" { } "mkdir $out";
in
{
  services.dnscrypt-proxy.enable = true;
  services.dnscrypt-proxy.package = dnscrypt-proxy;

  test = ''

    echo >&2 "checking dnscrypt-proxy service in /Library/LaunchDaemons"
    grep -q "org.nixos.dnscrypt-proxy" --  ${config.out}/Library/LaunchDaemons/org.nixos.dnscrypt-proxy.plist
    grep -q "dnscrypt-proxy-start" -- ${config.out}/Library/LaunchDaemons/org.nixos.dnscrypt-proxy.plist

    echo >&2 "checking dnscrypt-proxy system user in /Library/LaunchDaemons"
    grep -q "_dnscrypt-proxy" -- ${config.out}/Library/LaunchDaemons/org.nixos.dnscrypt-proxy.plist
  '';
}
