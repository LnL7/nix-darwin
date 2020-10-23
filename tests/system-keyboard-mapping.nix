{ config, pkgs, ... }:

{
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;
  system.keyboard.remapCapsLockToEscape = true;
  system.keyboard.nonUS.remapTilde = true;
  system.keyboard.swapLeftCommandAndLeftAlt = true;

  test = ''
    echo checking keyboard mappings in /activate >&2
    grep "hidutil property --set '{\"UserKeyMapping\":.*}'" ${config.out}/activate
    grep "\"HIDKeyboardModifierMappingSrc\":30064771129" ${config.out}/activate
    grep "\"HIDKeyboardModifierMappingSrc\":30064771172" ${config.out}/activate
    grep "\"HIDKeyboardModifierMappingDst\":30064771113" ${config.out}/activate
    grep "\"HIDKeyboardModifierMappingDst\":30064771125" ${config.out}/activate
    grep "\"HIDKeyboardModifierMappingDst\":30064771296" ${config.out}/activate
    grep "\"HIDKeyboardModifierMappingDst\":30064771298" ${config.out}/activate
    grep "\"HIDKeyboardModifierMappingDst\":30064771299" ${config.out}/activate
  '';
}
