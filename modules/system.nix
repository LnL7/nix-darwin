{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.system;

in {
  options = {

    system.build = mkOption {
      internal = true;
      type = types.attrsOf types.package;
      default = {};
      description = ''
        Attribute set of derivation used to setup the system.
      '';
    };

    system.path = mkOption {
      internal = true;
      type = types.package;
      description = ''
        The packages you want in the system environment.
      '';
    };

    # Used by <nixos/modules/system/etc/etc.nix>
    system.activationScripts = mkOption { internal = true; };

  };

  config = {

    system.build.toplevel = pkgs.buildEnv {
      name = "nixdarwin-system";
      paths = [ cfg.path cfg.build.etc ];
    };

  };
}
