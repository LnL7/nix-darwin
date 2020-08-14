{ nixpkgs ? <nixpkgs>, configuration ? <darwin-config>, system ? builtins.currentSystem
, pkgs ? import nixpkgs { inherit system; }
}:

let
  baseModules = import ./modules/module-list.nix;
  modules = [ configuration packages ] ++ baseModules;

  packages = { config, lib, pkgs, ... }: {
    _file = ./default.nix;
    config = {
      _module.args.pkgs = import nixpkgs config.nixpkgs;
      nixpkgs.system = system;
    };
  };

  eval = pkgs.lib.evalModules {
    inherit modules;
    args = { inherit baseModules modules; };
    specialArgs = { modulesPath = ./modules; };
    check = true;
  };

  # Was moved in nixpkgs #82751, so both need to be handled here until 20.03 is deprecated.
  # https://github.com/NixOS/nixpkgs/commits/dcdd232939232d04c1132b4cc242dd3dac44be8c
  _module = eval._module or eval.config._module;

  # The source code of this repo needed by the [un]installers.
  nix-darwin = pkgs.lib.cleanSource (
    pkgs.lib.cleanSourceWith {
      # We explicitly specify a name here otherwise `cleanSource` will use the
      # basename of ./.  which might be different for different clones of this
      # repo leading to non-reproducible outputs.
      name = "nix-darwin";
      src = ./.;
    }
  );
in

{
  inherit (_module.args) pkgs;
  inherit (eval) options config;

  system = eval.config.system.build.toplevel;

  installer = pkgs.callPackage ./pkgs/darwin-installer { inherit nix-darwin; };
  uninstaller = pkgs.callPackage ./pkgs/darwin-uninstaller { inherit nix-darwin; };
}
