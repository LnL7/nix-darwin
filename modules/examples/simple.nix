{ config, lib, pkgs, ... }:
{

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [ pkgs.nix-repl
    ];

  programs.bash.enable = true;
  programs.bash.interactiveShellInit = ''
    # Edit the NIX_PATH entries below or put the nix-darwin repository in
    # ~/.nix-defexpr/darwin and your configuration in ~/.nixpkgs/darwin-config.nix

    export NIX_PATH=darwin=$HOME/.nix-defexpr/darwin:darwin-config=$HOME/.nixpkgs/darwin-config.nix:$NIX_PATH
  '';

  services.activate-system.enable = true;

}
