{ config, lib, ... }:

with lib;

{
  options = {
    system.defaults.CustomUserPreferences = mkOption {
      type = types.attrs;
      default = { };
      example = {
        "NSGlobalDomain" = { "TISRomanSwitchState" = 1; };
        "com.apple.Safari" = {
          "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" =
            true;
        };
      };
      description = ''
        Sets custom user preferences
      '';
    };

    system.defaults.CustomSystemPreferences = mkOption {
      type = types.attrs;
      default = { };
      example = {
        "NSGlobalDomain" = { "TISRomanSwitchState" = 1; };
        "com.apple.Safari" = {
          "com.apple.Safari.ContentPageGroupIdentifier.WebKit2DeveloperExtrasEnabled" =
            true;
        };
      };
      description = ''
        Sets custom system preferences
      '';
    };

  };
}
