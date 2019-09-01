{ config, lib, ... }:

with lib;

{
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

  };
}
