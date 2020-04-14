{ config, pkgs, ... }:

{
  services.activate-system.enable = true;
  launchd.labelPrefix = "org.nix-darwin";

  test = ''
    echo checking activation service in /Library/LaunchDaemons >&2
    grep "org.nix-darwin.activate-system" ${config.out}/Library/LaunchDaemons/org.nix-darwin.activate-system.plist

    echo checking activation of /run/current-system >&2
    script=$(cat ${config.out}/Library/LaunchDaemons/org.nix-darwin.activate-system.plist | awk -F'[< ]' '$3 ~ "^/nix/store/.*" {print $3}')
    grep "ln -sfn .* /run/current-system" "$script"
  '';
}
