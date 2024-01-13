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
    class = "darwin";
    modules = modules ++ [ argsModule ] ++ baseModules;
    specialArgs = { modulesPath = builtins.toString ./modules; } // specialArgs;
  });
  
  withExtraAttrs = module:
    {
      inherit (module._module.args) pkgs;
      inherit (module) options config _module;
      system = module.config.system.build.toplevel;
      extendModules = args: withExtraAttrs (module.extendModules args);
    };
in withExtraAttrs eval
