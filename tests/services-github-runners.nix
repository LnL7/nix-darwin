{ config, pkgs, ... }:
{
  services.github-runners."a-runner" = {
    enable = true;
    url = "https://github.com/nixos/nixpkgs";
    tokenFile = "/secret/path/to/a/github/token";
    # We need an overridable derivation but cannot use the actual github-runner package
    # since it still relies on Node.js 16 which is marked as insecure.
    package = pkgs.hello;
  };

  test = ''
    echo >&2 "checking github-runner service in /Library/LaunchDaemons"
    grep "org.nixos.github-runner-a-runner" ${config.out}/Library/LaunchDaemons/org.nixos.github-runner-a-runner.plist
    grep "<string>_github-runner</string>" ${config.out}/Library/LaunchDaemons/org.nixos.github-runner-a-runner.plist

    echo >&2 "checking for user in /activate"
    grep "GitHub Runner service user" ${config.out}/activate
  '';
}
