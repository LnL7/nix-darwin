{ nixpkgs ? <nixpkgs>, configuration ? <darwin-config>, system ? builtins.currentSystem
, pkgs ? import nixpkgs { inherit system; }
}:

let

  packages = { config, lib, pkgs, ... }: {
    config = {
      _module.args.pkgs = import nixpkgs {
        inherit system;
        inherit (config.nixpkgs) config;
      };
    };
  };

  eval = pkgs.lib.evalModules {
    check = true;
    modules =
      [ configuration
        packages
        ./modules/alias.nix
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
        ./modules/security
        ./modules/security/wrappers.nix
        ./modules/services/activate-system.nix
        ./modules/services/khd.nix
        ./modules/services/kwm.nix
        ./modules/services/emacs.nix
        ./modules/services/mopidy.nix
        ./modules/services/nix-daemon.nix
        ./modules/services/nix-gc.nix
        ./modules/programs/bash.nix
        ./modules/programs/fish.nix
        ./modules/programs/man.nix
        ./modules/programs/nix-script.nix
        ./modules/programs/tmux.nix
        ./modules/programs/vim.nix
        ./modules/programs/zsh
      ];
  };

in

{
  inherit (eval.config._module.args) pkgs;
  inherit (eval) options config;

  system = eval.config.system.build.toplevel;
}
