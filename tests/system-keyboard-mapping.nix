[
  (
    # There are `globalKeyMappings` and no `deviceSpecificKeyMappings`.
    { config, pkgs, ... }: {
      system.keyboard.enableKeyMapping = true;
      system.keyboard.remapCapsLockToControl = true;
      system.keyboard.nonUS.remapTilde = true;

      test = ''
        echo checking keyboard mappings in ${config.out}/user/Library/LaunchAgents/org.nixos.keyboard.plist >&2

        ACTIVATION_SCRIPT="$(grep apply-keybindings ${config.out}/user/Library/LaunchAgents/org.nixos.keyboard.plist |
          sed 's%^.*<string>\(/nix/store/.*/apply-keybindings\)</string>$%\1%')"

        grep "hidutil property --set '{\"UserKeyMapping\":.*}'" "$ACTIVATION_SCRIPT"

        # There is no specific product ID configured, so this should not match.
        ! grep "hidutil property --matching '{\"ProductID\":.*}' --set '{\"UserKeyMapping\":.*}'" "$ACTIVATION_SCRIPT"

        # 30064771129 == 0x700000000 | 0x39 == "Caps Lock"
        grep "\"HIDKeyboardModifierMappingSrc\":30064771129" "$ACTIVATION_SCRIPT"

        # 30064771296 ==  0x700000000 | 0xE0 == "Keyboard Left Control"
        grep "\"HIDKeyboardModifierMappingDst\":30064771296" "$ACTIVATION_SCRIPT"

        # 30064771122 == 0x700000000 | 0x32 == "Keyboard Non-US # and ~"
        grep "\"HIDKeyboardModifierMappingSrc\":30064771122" "$ACTIVATION_SCRIPT"

        # 30064771125 ==  0x700000000 | 0x35 == "Keyboard Grave Accent and Tilde"
        grep "\"HIDKeyboardModifierMappingDst\":30064771125" "$ACTIVATION_SCRIPT"
      '';
    }
  )

  (
    # There are only `deviceSpecificKeyMappings`.
    { config, pkgs, ... }: {
      system.keyboard.enableKeyMapping = true;
      system.keyboard.mappings = [
        {
          productId = 638;
          vendorId = 1452;
          # Device ID of the internal MacBook keyboard (check the output of
          # `system_profiler SPUSBDataType` or find it in Apple menu → System
          # Report → Hardware → USB)
          mappings = {
            "Keyboard Caps Lock" = "Keyboard Left Function (fn)";
            "Keyboard Left Alt" = "Keyboard Left GUI";
            "Keyboard Left Function (fn)" = "Keyboard Left Control";
            "Keyboard Left GUI" = "Keyboard Left Alt";
            "Keyboard Right Alt" = "Keyboard Right Control";
            "Keyboard Right GUI" = "Keyboard Right Alt";
          };
        }
      ];

      test = ''
        echo checking keyboard mappings in ${config.out}/user/Library/LaunchAgents/org.nixos.keyboard-638.plist >&2

        ACTIVATION_SCRIPT="$(grep apply-keybindings ${config.out}/user/Library/LaunchAgents/org.nixos.keyboard-638.plist |
          sed 's%^.*<string>\(/nix/store/.*/apply-keybindings\)</string>$%\1%')"

        # There are no global key mappings, so this should not match.
        ! grep "hidutil property --set '{\"UserKeyMapping\":.*}'" $ACTIVATION_SCRIPT

        grep "hidutil property --matching '{\"ProductID\":.*}' --set '{\"UserKeyMapping\":.*}'" $ACTIVATION_SCRIPT

        # 30064771129 == 0x700000000 | 0x39 == "Caps Lock"
        grep "\"HIDKeyboardModifierMappingSrc\":30064771129" $ACTIVATION_SCRIPT

        # 1095216660483 == "Keyboard Left Function (fn)" (not documented)
        grep "\"HIDKeyboardModifierMappingDst\":1095216660483" $ACTIVATION_SCRIPT

        # 30064771129 == 0x700000000 | 0x39 == "Caps Lock"
        grep "\"HIDKeyboardModifierMappingSrc\":30064771129" $ACTIVATION_SCRIPT

        # 1095216660483 == "Keyboard Left Function (fn)" (not documented)
        grep "\"HIDKeyboardModifierMappingDst\":1095216660483" $ACTIVATION_SCRIPT

        # 30064771298 == 0x700000000 | 0xE2 == "Keyboard Left Alt"
        grep "\"HIDKeyboardModifierMappingSrc\":30064771298" $ACTIVATION_SCRIPT

        # 30064771299 == 0x700000000 | 0xE3 =="Keyboard Left GUI"
        grep "\"HIDKeyboardModifierMappingDst\":30064771299" $ACTIVATION_SCRIPT

        # 1095216660483 == "Keyboard Left Function (fn)" (not documented)
        grep "\"HIDKeyboardModifierMappingSrc\":1095216660483" $ACTIVATION_SCRIPT

        # 30064771296 ==  0x700000000 | 0xE0 == "Keyboard Left Control"
        grep "\"HIDKeyboardModifierMappingDst\":30064771296" $ACTIVATION_SCRIPT

        # 30064771298 == 0x700000000 | 0xE2 == "Keyboard Left Alt"
        grep "\"HIDKeyboardModifierMappingSrc\":30064771298" $ACTIVATION_SCRIPT

        # 30064771299 == 0x700000000 | 0xE3 =="Keyboard Left GUI"
        grep "\"HIDKeyboardModifierMappingDst\":30064771299" $ACTIVATION_SCRIPT

        # 30064771299 == 0x700000000 | 0xE3 =="Keyboard Left GUI"
        grep "\"HIDKeyboardModifierMappingSrc\":30064771299" $ACTIVATION_SCRIPT

        # 30064771298 == 0x700000000 | 0xE2 == "Keyboard Left Alt"
        grep "\"HIDKeyboardModifierMappingDst\":30064771296" $ACTIVATION_SCRIPT
      '';
    }
  )
]
