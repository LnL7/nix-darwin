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
      assertions = [ {
        # Ensure that nixpkgs.* options are not set when pkgs is set
        assertion = pkgs == null || (config.nixpkgs.config == { } && config.nixpkgs.overlays == [ ]);
        message = ''
          `nixpkgs` options are disabled when `pkgs` is supplied through `darwinSystem`.
        '';
      } ];

      _module.args.pkgs = if pkgs != null then pkgs else import inputs.nixpkgs config.nixpkgs;

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
