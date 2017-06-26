{ config, lib, ... }:

with lib;

{
  options = {

    system.defaults.NSGlobalDomain.AppleKeyboardUIMode = mkOption {
      type = types.nullOr (types.enum [ 3 ]);
      default = null;
      description = ''
        Configures the keyboard control behavior.  Mode 3 enables full keyboard control.
      '';
    };

    system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to enable the press-and-hold feature.  The default is true.
      '';
    };

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

    system.defaults.NSGlobalDomain.NSAutomaticCapitalizationEnabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to enable automatic capitalization.  The default is true.
      '';
    };

    system.defaults.NSGlobalDomain.NSAutomaticQuoteSubstitutionEnabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to enable smart quote substitution.  The default is true.
      '';
    };

    system.defaults.NSGlobalDomain.NSAutomaticDashSubstitutionEnabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to enable smart dash substitution.  The default is true.
      '';
    };

    system.defaults.NSGlobalDomain.NSAutomaticPeriodSubstitutionEnabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to enable smart period substitution.  The default is true.
      '';
    };

    system.defaults.NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to enable automatic spelling correction.  The default is true.
      '';
    };

    system.defaults.NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to save new documents to iCloud by default.  The default is true.
      '';
    };

    system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to use expanded save panel by default.  The default is false.
      '';
    };

    system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode2 = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to use expanded save panel by default.  The default is false.
      '';
    };

    system.defaults.NSGlobalDomain."com.apple.trackpad.enableSecondaryClick" = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to enable trackpad secondary click.  The default is true.
      '';
    };

    system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to enable "Natural" scrolling direction.  The default is true.
      '';
    };

    system.defaults.NSGlobalDomain."com.apple.mouse.tapBehavior" = mkOption {
      type = types.nullOr (types.enum [ 1 ]);
      default = null;
      description = ''
        Configures the trackpad tap behavior.  Mode 1 enables tap to click.
      '';
    };

    system.defaults.NSGlobalDomain."com.apple.trackpad.trackpadCornerClickBehavior" = mkOption {
      type = types.nullOr (types.enum [ 1 ]);
      default = null;
      description = ''
        Configures the trackpad corner click behavior.  Mode 1 enables right click.
      '';
    };

  };
}
