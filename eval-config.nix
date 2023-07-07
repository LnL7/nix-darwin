{ lib }:
let
  nixpkgs-lib = lib;
in

{ system ? builtins.currentSystem or "x86_64-darwin"
, pkgs ? null
, lib ? nixpkgs-lib
, modules
, inputs
, baseModules ? import ./modules/module-list.nix
, specialArgs ? { }
, check ? true
}@args:

let
  argsModule = {
    _file = ./eval-config.nix;
    config = {
      _module.args = {
        inherit baseModules inputs modules;
      };
    };
  };

  pkgsModule = { config, inputs, ... }: {
    _file = ./eval-config.nix;
    config = {
      _module.args.pkgs = lib.mkIf (pkgs != null) (lib.mkForce pkgs);

      nixpkgs.source = lib.mkDefault inputs.nixpkgs;

      # This permits the configuration to override the passed-in
      # system.
      nixpkgs.system = lib.mkDefault system;
    };
  };

  eval = lib.evalModules (builtins.removeAttrs args [ "lib" "inputs" "pkgs" "system" ] // {
    modules = modules ++ [ argsModule pkgsModule ] ++ baseModules;
    specialArgs = { modulesPath = builtins.toString ./modules; } // specialArgs;
  });
in

{
  inherit (eval._module.args) pkgs;
  inherit (eval) options config;

  system = eval.config.system.build.toplevel;
}
