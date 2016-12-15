{ config, lib, pkgs, ... }:
{

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [ pkgs.nix-repl
    ];

  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.bash.enable = true;

  # Recreate /run/current-system symlink after boot.
  services.activate-system.enable = true;

}
