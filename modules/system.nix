{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.system;

in {
  options = {

    system.build = mkOption {
      internal = true;
      default = {};
      description = ''
        Attribute set of derivation used to setup the system.
      '';
    };

    system.activationScripts = mkOption {
      internal = true;
      default = {};
    };

  };

  config = {

    system.build.toplevel = pkgs.buildEnv {
      name = "nixdarwin-system";
      paths = [ cfg.build.path cfg.build.etc ];
    };

  };
}
