{ config, lib, pkgs, ... }:
{

  # List packages installed in system profile. To search by name, run:
  # $ nix-env -qaP | grep wget
  environment.systemPackages =
    [ # Include nix-tools
      config.system.build.nix

      pkgs.nix-repl
    ];

  environment.etc."bashrc".text = ''
    # /etc/bashrc: DO NOT EDIT -- this file has been generated automatically.
    # This file is read for interactive shells.

    # Only execute this file once per shell.
    if [ -n "$__ETC_BASHRC_SOURCED" -o -n "$NOSYSBASHRC" ]; then return; fi
    __ETC_BASHRC_SOURCED=1

    export NIX_PATH=nixpkgs=$HOME/.nix-defexpr/nixpkgs:darwin=$HOME/.nix-defexpr/darwin:darwin-config=$HOME/.nixpkgs/darwin-config.nix:$NIX_PATH

    export PATH=${config.environment.systemPath}''${PATH:+:$PATH}

    ${config.system.build.setEnvironment}
    ${config.system.build.setAliases}
  '';
}
