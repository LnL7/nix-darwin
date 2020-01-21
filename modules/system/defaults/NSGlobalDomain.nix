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

    system.defaults.NSGlobalDomain.AppleFontSmoothing = mkOption {
      type = types.nullOr (types.enum [ 0 1 2 ]);
      default = null;
      description = ''
        Sets the level of font smoothing (sub-pixel font rendering).
      '';
    };

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

    system.defaults.NSGlobalDomain.AppleShowAllExtensions = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to show all file extensions in finder. The default is false.
      '';
    };

    system.defaults.NSGlobalDomain.AppleShowScrollBars = mkOption {
      type = types.nullOr (types.enum [ "WhenScrolling" "Automatic" "Always" ]);
      default = null;
      description = ''
        When to show the scrollbars. Options are 'WhenScrolling', 'Automatic' and 'Always'.
      '';
    };

    system.defaults.NSGlobalDomain.NSAutomaticCapitalizationEnabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to enable automatic capitalization.  The default is true.
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

    system.defaults.NSGlobalDomain.NSAutomaticQuoteSubstitutionEnabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to enable smart quote substitution.  The default is true.
      '';
    };

    system.defaults.NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to enable automatic spelling correction.  The default is true.
      '';
    };

    system.defaults.NSGlobalDomain.NSDisableAutomaticTermination = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to disable the automatic termination of inactive apps.
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

    system.defaults.NSGlobalDomain.NSTableViewDefaultSizeMode = mkOption {
      type = types.nullOr (types.enum [ 1 2 3 ]);
      default = null;
      description = ''
        Sets the size of the finder sidebar icons: 1 (small), 2 (medium) or 3 (large). The default is 3.
      '';
    };

    system.defaults.NSGlobalDomain.NSTextShowsControlCharacters = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to display ASCII control characters using caret notation in standard text views. The default is false.
      '';
    };

    system.defaults.NSGlobalDomain.NSUseAnimatedFocusRing = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to enable the focus ring animation. The default is true.
      '';
    };

    system.defaults.NSGlobalDomain.NSScrollAnimationEnabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to enable smooth scrolling. The default is true.
      '';
    };

    system.defaults.NSGlobalDomain.NSWindowResizeTime = mkOption {
      type = types.nullOr float;
      default = null;
      example = "0.20";
      description = ''
        Sets the speed speed of window resizing. The default is given in the example.
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

    system.defaults.NSGlobalDomain.PMPrintingExpandedStateForPrint = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to use the expanded print panel by default. The default is false.
      '';
    };

    system.defaults.NSGlobalDomain.PMPrintingExpandedStateForPrint2 = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to use the expanded print panel by default. The default is false.
      '';
    };

    system.defaults.NSGlobalDomain."com.apple.keyboard.fnState" = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Use F1, F2, etc. keys as standard function keys.
      '';
    };

    system.defaults.NSGlobalDomain."com.apple.mouse.tapBehavior" = mkOption {
      type = types.nullOr (types.enum [ 1 ]);
      default = null;
      description = ''
        Configures the trackpad tap behavior.  Mode 1 enables tap to click.
      '';
    };

    system.defaults.NSGlobalDomain."com.apple.sound.beep.volume" = mkOption {
      type = types.nullOr float;
      default = null;
      description = ''
        # Apple menu > System Preferences > Sound
        Sets the beep/alert volume level from 0.000 (muted) to 1.000 (100% volume).

        75% = 0.7788008
        50% = 0.6065307
        25% = 0.4723665
      '';
    };

    system.defaults.NSGlobalDomain."com.apple.sound.beep.feedback" = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        # Apple menu > System Preferences > Sound
        Make a feedback sound when the system volume changed. This setting accepts
        the integers 0 or 1. Defaults to 1.
      '';
    };

    system.defaults.NSGlobalDomain."com.apple.trackpad.enableSecondaryClick" = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to enable trackpad secondary click.  The default is true.
      '';
    };

    system.defaults.NSGlobalDomain."com.apple.trackpad.trackpadCornerClickBehavior" = mkOption {
      type = types.nullOr (types.enum [ 1 ]);
      default = null;
      description = ''
        Configures the trackpad corner click behavior.  Mode 1 enables right click.
      '';
    };

    system.defaults.NSGlobalDomain."com.apple.trackpad.scaling" = mkOption {
      type = types.nullOr float;
      default = null;
      description = ''
        Configures the trackpad tracking speed (0 to 3).  The default is "1".
      '';
    };

    system.defaults.NSGlobalDomain."com.apple.springing.enabled" = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to enable spring loading (expose) for directories.
      '';
    };

    system.defaults.NSGlobalDomain."com.apple.springing.delay" = mkOption {
      type = types.nullOr float;
      default = null;
      example = "1.0";
      description = ''
        Set the spring loading delay for directories. The default is given in the example.
      '';
    };

    system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to enable "Natural" scrolling direction.  The default is true.
      '';
    };

    system.defaults.NSGlobalDomain.AppleMeasurementUnits = mkOption {
      type = types.nullOr (types.enum [ "Centimeters" "Inches" ]);
      default = null;
      description = ''
        Whether to use centimeters (metric) or inches (US, UK) as the measurement unit.  The default is based on region settings.
      '';
    };

    system.defaults.NSGlobalDomain.AppleMetricUnits = mkOption {
      type = types.nullOr (types.enum [ 0 1 ]);
      default = null;
      description = ''
        Whether to use the metric system.  The default is based on region settings.
      '';
    };

    system.defaults.NSGlobalDomain.AppleTemperatureUnit = mkOption {
      type = types.nullOr (types.enum [ "Celsius" "Fahrenheit" ]);
      default = null;
      description = ''
        Whether to use Celsius or Fahrenheit.  The default is based on region settings.
      '';
    };

    system.defaults.NSGlobalDomain._HIHideMenuBar = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to autohide the menu bar.  The default is false.
      '';
    };

  };

}
