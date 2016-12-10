{ pkgs ? import <nixpkgs> {}, config ? <darwin-config> }:

let

  eval = pkgs.lib.evalModules {
    check = true;
    args = { inherit pkgs; };
    modules =
      [ config
        ./modules/system
        ./modules/system/activation-scripts.nix
        ./modules/system/defaults
        ./modules/system/etc.nix
        ./modules/system/launchd.nix
        ./modules/environment
        ./modules/launchd
        ./modules/services/activate-system.nix
        ./modules/services/nix-daemon.nix
        ./modules/programs/tmux.nix
        ./modules/programs/nix-darwin.nix
      ];
  };

in
  eval
