{ config, pkgs, ... }:

{
  services.activate-system.enable = true;
  environment.currentSystemPath = /run/to/current/system;

  test = ''
    echo checking activation service in /Library/LaunchDaemons >&2
    grep "org.nixos.activate-system" ${config.out}/Library/LaunchDaemons/org.nixos.activate-system.plist

    echo checking activation of /run/to/current/system >&2
    script=$(cat ${config.out}/Library/LaunchDaemons/org.nixos.activate-system.plist | awk -F'[< ]' '$3 ~ "^/nix/store/.*" {print $3}')
    grep "ln -sfn .* /run/to/current/system" "$script"
  '';
}
