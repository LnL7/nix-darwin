{ config, lib, ... }:

with lib;

let

  cfg = config.system.defaults;

in

{
  options = {

    system.defaults.global.InitialKeyRepeat = mkOption {
      type = types.nullOr types.int;
      default = null;
    };

    system.defaults.global.KeyRepeat = mkOption {
      type = types.nullOr types.int;
      default = null;
    };

  };

  config = {
    system.activationScripts.defaults.text = ''
      # Set defaults
      echo "writing defaults..." >&2

    '' + optionalString (cfg.global.InitialKeyRepeat != null) ''
      defaults write -g InitialKeyRepeat -int ${toString cfg.global.InitialKeyRepeat}
    '' + optionalString (cfg.global.KeyRepeat != null) ''
      defaults write -g KeyRepeat -int ${toString cfg.global.KeyRepeat}
    '';
  };
}
