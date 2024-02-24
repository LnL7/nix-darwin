{ config, pkgs, ... }:
{
  users = {
    knownUsers = [ "github-runner" ];
    knownGroups = [ "github-runner" ];
  };

  services.github-runners."a-runner" = {
    enable = true;
    url = "https://github.com/nixos/nixpkgs";
    tokenFile = pkgs.writeText "fake-token" "not-a-token";
    package = pkgs.runCommand "github-runner-0.0.0" { } "touch $out";
  };

  test = ''
    echo >&2 "checking github-runner service in /Library/LaunchDaemons"
    grep "org.nixos.github-runner-a-runner" ${config.out}/Library/LaunchDaemons/org.nixos.github-runner-a-runner.plist
    grep "<string>github-runner</string>" ${config.out}/Library/LaunchDaemons/org.nixos.github-runner-a-runner.plist

    echo >&2 "checking for user in /activate"
    grep "GitHub Runner service user" ${config.out}/activate
  '';
}
