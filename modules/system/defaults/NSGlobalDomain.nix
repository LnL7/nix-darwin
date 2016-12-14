{ config, lib, ... }:

with lib;

{
  options = {

    system.defaults.NSGlobalDomain.InitialKeyRepeat = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        # Apple menu > System Preferences > Keyboard
        If you press and hold certain keyboard keys when in a text area, the key’s character begins to repeat.
        For example, the Delete key continues to remove text for as long as you hold it down.

        This sets how long you must hold down the key before it starts repeating.
      '';
    };

    system.defaults.NSGlobalDomain.KeyRepeat = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        # Apple menu > System Preferences > Keyboard
        If you press and hold certain keyboard keys when in a text area, the key’s character begins to repeat.
        For example, the Delete key continues to remove text for as long as you hold it down.

        This sets how fast it repeats once it starts.
      '';
    };

  };
}
