{ config, lib, ... }:

with lib;

let
  isFloat = x: isString x && builtins.match "^[+-]?([0-9]*[.])?[0-9]+$" x != null;

  float = mkOptionType {
    name = "float";
    description = "float";
    check = isFloat;
    merge = options.mergeOneOption;
  };

in {
  options = {

    system.defaults.".GlobalPreferences"."com.apple.sound.beep.sound" =
      mkOption {
        type = types.nullOr (types.path);
        default = null;
        description = ''
          Sets the system-wide alert sound. Found under "Sound Effects" in the
          "Sound" section of "System Preferences". Look in
          "/System/Library/Sounds" for possible candidates.
        '';
      };

    system.defaults.".GlobalPreferences"."com.apple.mouse.scaling" =
      mkOption {
        type = types.nullOr float;
        default = null;
        description = ''
          Sets the mouse tracking speed. Found in the "Mouse" section of
          "System Preferences". Set to -1 to disable mouse acceleration.
        '';
      };
  };
}
