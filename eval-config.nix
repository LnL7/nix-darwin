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

  libExtended = lib.extend (self: super: {
    # Added in nixpkgs #136909, adds forward compatibility until 22.03 is deprecated.
    literalExpression = super.literalExpression or super.literalExample;
    literalDocBook = super.literalDocBook or super.literalExample;
  });

  eval = libExtended.evalModules (builtins.removeAttrs args [ "lib" "inputs" "pkgs" "system" ] // {
    modules = modules ++ [ argsModule pkgsModule ] ++ baseModules;
    specialArgs = { modulesPath = builtins.toString ./modules; } // specialArgs;
  });

  # Was moved in nixpkgs #82751, so both need to be handled here until 20.03 is deprecated.
  # https://github.com/NixOS/nixpkgs/commits/dcdd232939232d04c1132b4cc242dd3dac44be8c
  _module = eval._module or eval.config._module;
in

{
  inherit (_module.args) pkgs;
  inherit (eval) options config;

  system = eval.config.system.build.toplevel;
}
