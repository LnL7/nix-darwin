{ config, lib, pkgs, ... }:

with lib;

{
  # Logs are enabled by default.
  # $ tail -f /var/log/ofborg.log
  services.ofborg.enable = true;
  # services.ofborg.configFile = "/var/lib/ofborg/config.json";

  # $ nix-channel --add https://github.com/NixOS/ofborg/archive/released.tar.gz ofborg
  # $ nix-channel --update
  services.ofborg.package = (import <ofborg> {}).ofborg.rs;

  # Keep nix-daemon updated.
  services.nix-daemon.enable = true;

  nix.gc.automatic = true;
  nix.gc.options = "--max-freed $((25 * 1024**3 - 1024 * $(df -P -k /nix/store | tail -n 1 | awk '{ print $4 }')))";

  # Manage user for ofborg, this enables creating/deleting users
  # depending on what modules are enabled.
  users.knownGroups = [ "ofborg" ];
  users.knownUsers = [ "ofborg" ];

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
