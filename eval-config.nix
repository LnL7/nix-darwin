#{ lib, system ? "x86_64-darwin", check ? true }:

{ configuration, inputs ? null, pkgs ? (import inputs.nixpkgs { system = system; }), lib ? pkgs.lib, check ? true, modules ? [], specialArgs ? {}, system ? "x86_64-darwin" }:

let
  darwinModules = import ./modules/module-list.nix;

  eval = lib.evalModules {
    modules = let
      initModule = { ... }: {
        _file = ./default.nix;
        config = {
          _module.args = {
            pkgs = pkgs;
            baseModules = darwinModules;
          } // (if inputs != null then inputs else {});
          nixpkgs.system = system;
          # TODO: assert pkgs.system == system?
        };
      };
    in [ initModule configuration ] ++ modules ++ darwinModules;
    specialArgs = { modulesPath = ./modules; } // specialArgs;
    inherit check;
  };

in {
  inherit pkgs; # TODO: why a round trip throug eval?
  inherit (eval) options config;

  system = eval.config.system.build.toplevel;
}

/*{ configuration, inputs, modules ? [], specialArgs ? {} }:

let
  baseModules = import ./modules/module-list.nix;
  evalModules = [ configuration packages ] ++ baseModules ++ modules;

  packages = { config, lib, pkgs, ... }: {
    _file = ./default.nix;
    config = {
      _module.args.inputs = inputs;
      _module.args.pkgs = import inputs.nixpkgs config.nixpkgs;
      nixpkgs.system = system;
    };
  };

  eval = lib.evalModules {
    modules = evalModules;
    args = { inherit baseModules; modules = evalModules; };
    specialArgs = { modulesPath = ./modules; } // specialArgs;
    check = true;
  };

  # Was moved in nixpkgs #82751, so both need to be handled here until 20.03 is deprecated.
  # https://github.com/NixOS/nixpkgs/commits/dcdd232939232d04c1132b4cc242dd3dac44be8c
  _module = eval._module or eval.config._module;
in

{
  inherit (_module.args) pkgs;
  inherit (eval) options config;

  system = eval.config.system.build.toplevel;
}*/
