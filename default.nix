{ pkgs ? import <nixpkgs> {}, config ? <darwin-config> }:

let

  eval = pkgs.lib.evalModules {
    check = true;
    modules =
      [ config
        ./modules/system
        ./modules/system/activation-scripts.nix
        ./modules/system/defaults
        ./modules/system/etc.nix
        ./modules/system/launchd.nix
        ./modules/nix/nix-darwin.nix
        ./modules/nix/nixpkgs.nix
        ./modules/environment
        ./modules/launchd
        ./modules/services/activate-system.nix
        ./modules/services/nix-daemon.nix
        ./modules/programs/tmux.nix
      ];
  };

  system = eval.config.system.build.toplevel;

in

{
  inherit (eval) config;
  inherit system;
}
