{ config, pkgs, ... }:

{
  test = ''
    echo checking activation service in /Library/LaunchDaemons >&2
    grep "org.nixos.activate-system" ${config.out}/Library/LaunchDaemons/org.nixos.activate-system.plist

    echo checking activation of /run/current-system >&2
    script=$(cat ${config.out}/Library/LaunchDaemons/org.nixos.activate-system.plist | awk -F'[< ]' '$6 ~ "^/nix/store/.*" {print $6}')
    grep "ln -sfn .* /run/current-system" "$script"
  '';
}
