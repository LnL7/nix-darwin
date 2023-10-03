{ lib
, modules
, baseModules ? import ./modules/module-list.nix
, specialArgs ? { }
, check ? true
}@args:

let
  argsModule = {
    _file = ./eval-config.nix;
    config = {
      _module.args = {
        inherit baseModules modules;
      };
    };
  };

  eval = lib.evalModules (builtins.removeAttrs args [ "lib" ] // {
    modules = modules ++ [ argsModule ] ++ baseModules;
    specialArgs = { modulesPath = builtins.toString ./modules; } // specialArgs;
  });
in

{
  inherit (eval._module.args) pkgs;
  inherit (eval) options config;
  inherit (eval) _module;

  system = eval.config.system.build.toplevel;
}
