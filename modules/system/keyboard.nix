{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.system.keyboard;
in

{
  options = {
    system.keyboard.enableKeyMapping = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable keyboard mappings.";
    };

    system.keyboard.remapCapsLockToControl = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to remap the Caps Lock key to Control.";
    };

    system.keyboard.remapCapsLockToEscape = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to remap the Caps Lock key to Escape.";
    };

    system.keyboard.userKeyMapping = mkOption {
      internal = true;
      type = types.listOf (types.attrsOf types.int);
      default = [];
      description = ''
        List of keyboard mappings to apply, for more information see
        <link xlink:href="https://developer.apple.com/library/content/technotes/tn2450/_index.html"/>.
      '';
    };
  };

  config = {

    warnings = mkIf (!cfg.enableKeyMapping && cfg.userKeyMapping != [])
      [ "system.keyboard.enableKeyMapping is not enabled, keyboard mappings will not be configured." ];

    system.keyboard.userKeyMapping = mkMerge [
      (mkIf cfg.remapCapsLockToControl [{ HIDKeyboardModifierMappingSrc = 30064771129; HIDKeyboardModifierMappingDst = 30064771296; }])
      (mkIf cfg.remapCapsLockToEscape [{ HIDKeyboardModifierMappingSrc = 30064771129; HIDKeyboardModifierMappingDst = 30064771113; }])
    ];

    system.activationScripts.keyboard.text = optionalString cfg.enableKeyMapping ''
      # Configuring keyboard
      echo "configuring keyboard..." >&2
      hidutil property --set '{"UserKeyMapping":${builtins.toJSON cfg.userKeyMapping}}' > /dev/null
    '';

  };
}
