{ nixpkgs ? <nixpkgs>, configuration ? <darwin-config>, system ? builtins.currentSystem
, pkgs ? import nixpkgs { inherit system; }
}:

let

  packages = { config, lib, pkgs, ... }: {
    _file = ./default.nix;
    config = {
      _module.args.pkgs = import nixpkgs config.nixpkgs;
      nixpkgs.system = system;
    };
  };

  eval = pkgs.lib.evalModules {
    specialArgs = { modulesPath = ./modules; };
    check = true;
    modules =
      [ configuration
        packages
        ./modules/alias.nix
        ./modules/system
        ./modules/system/checks.nix
        ./modules/system/activation-scripts.nix
        ./modules/system/applications.nix
        ./modules/system/defaults-write.nix
        ./modules/system/defaults/LaunchServices.nix
        ./modules/system/defaults/NSGlobalDomain.nix
        ./modules/system/defaults/dock.nix
        ./modules/system/defaults/finder.nix
        ./modules/system/defaults/screencapture.nix
        ./modules/system/defaults/smb.nix
        ./modules/system/defaults/trackpad.nix
        ./modules/system/etc.nix
        ./modules/system/keyboard.nix
        ./modules/system/launchd.nix
        ./modules/system/shells.nix
        ./modules/system/version.nix
        ./modules/time
        ./modules/networking
        ./modules/nix
        ./modules/nix/nix-darwin.nix
        ./modules/nix/nix-info.nix
        ./modules/nix/nixpkgs.nix
        ./modules/environment
        ./modules/launchd
        ./modules/services/activate-system
        ./modules/services/buildkite-agent.nix
        ./modules/services/chunkwm.nix
        ./modules/services/emacs.nix
        ./modules/services/khd
        ./modules/services/kwm
        ./modules/services/mail/offlineimap.nix
        ./modules/services/mopidy.nix
        ./modules/services/nix-daemon.nix
        ./modules/services/nix-gc
        ./modules/services/ofborg
        ./modules/services/postgresql
        ./modules/services/privoxy
        ./modules/services/redis
        ./modules/services/skhd
        ./modules/programs/bash
        ./modules/programs/fish.nix
        ./modules/programs/gnupg.nix
        ./modules/programs/man.nix
        ./modules/programs/info
        ./modules/programs/nix-index
        ./modules/programs/nix-script.nix
        ./modules/programs/ssh
        ./modules/programs/tmux.nix
        ./modules/programs/vim.nix
        ./modules/programs/zsh
        ./modules/users
        ./modules/users/nixbld
      ];
  };

in

{
  inherit (eval.config._module.args) pkgs;
  inherit (eval) options config;

  system = eval.config.system.build.toplevel;

  installer = pkgs.callPackage ./pkgs/darwin-installer {};
  uninstaller = pkgs.callPackage ./pkgs/darwin-uninstaller {};
}
