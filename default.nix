{ pkgs ? import <nixpkgs> {}, config ? <darwin-config> }:

let

  eval = pkgs.lib.evalModules {
    check = true;
    modules =
      [ config
        ./modules/system
        ./modules/system/activation-scripts.nix
        ./modules/system/defaults-write.nix
        ./modules/system/defaults/NSGlobalDomain.nix
        ./modules/system/defaults/LaunchServices.nix
        ./modules/system/defaults/dock.nix
        ./modules/system/defaults/finder.nix
        ./modules/system/defaults/trackpad.nix
        ./modules/system/etc.nix
        ./modules/system/launchd.nix
        ./modules/time
        ./modules/nix
        ./modules/nix/nix-darwin.nix
        ./modules/nix/nixpkgs.nix
        ./modules/environment
        ./modules/launchd
        ./modules/services/activate-system.nix
        ./modules/services/nix-daemon.nix
        ./modules/programs/bash.nix
        ./modules/programs/tmux.nix
        ./modules/programs/zsh.nix
      ];
  };

  system = eval.config.system.build.toplevel;

in

{
  inherit (eval) options config;
  inherit system;
}
