{ config, lib, ... }:

with lib;

let
  # Should only be used with options that previously used floats defined as strings.
  inherit (config.lib.defaults.types) floatWithDeprecationError;
in {
  options = {

    system.defaults.NSGlobalDomain.AppleShowAllFiles = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to always show hidden files. The default is false.
      '';
    };

    system.defaults.NSGlobalDomain.AppleEnableMouseSwipeNavigateWithScrolls = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Enables swiping left or right with two fingers to navigate backward or forward. The default is true.
      '';
    };

    system.defaults.NSGlobalDomain.AppleEnableSwipeNavigateWithScrolls = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Enables swiping left or right with two fingers to navigate backward or forward. The default is true.
      '';
    };

    system.defaults.NSGlobalDomain.AppleFontSmoothing = mkOption {
      type = types.nullOr (types.enum [ 0 1 2 ]);
      default = null;
      description = lib.mdDoc ''
        Sets the level of font smoothing (sub-pixel font rendering).
      '';
    };

    system.defaults.NSGlobalDomain.AppleInterfaceStyle = mkOption {
      type = types.nullOr (types.enum [ "Dark" ]);
      default = null;
      description = lib.mdDoc ''
        Set to 'Dark' to enable dark mode, or leave unset for normal mode.
      '';
    };

    system.defaults.NSGlobalDomain.AppleInterfaceStyleSwitchesAutomatically = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to automatically switch between light and dark mode. The default is false.
      '';
    };

    system.defaults.NSGlobalDomain.AppleKeyboardUIMode = mkOption {
      type = types.nullOr (types.enum [ 3 ]);
      default = null;
      description = lib.mdDoc ''
        Configures the keyboard control behavior.  Mode 3 enables full keyboard control.
      '';
    };

    system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to enable the press-and-hold feature.  The default is true.
      '';
    };

    system.defaults.NSGlobalDomain.AppleShowAllExtensions = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to show all file extensions in Finder. The default is false.
      '';
    };

    system.defaults.NSGlobalDomain.AppleShowScrollBars = mkOption {
      type = types.nullOr (types.enum [ "WhenScrolling" "Automatic" "Always" ]);
      default = null;
      description = lib.mdDoc ''
        When to show the scrollbars. Options are 'WhenScrolling', 'Automatic' and 'Always'.
      '';
    };

    system.defaults.NSGlobalDomain.AppleScrollerPagingBehavior = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Jump to the spot that's clicked on the scroll bar. The default is false.
      '';
    };

    system.defaults.NSGlobalDomain.NSAutomaticCapitalizationEnabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to enable automatic capitalization.  The default is true.
      '';
    };

    system.defaults.NSGlobalDomain.NSAutomaticDashSubstitutionEnabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to enable smart dash substitution.  The default is true.
      '';
    };

    system.defaults.NSGlobalDomain.NSAutomaticPeriodSubstitutionEnabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to enable smart period substitution.  The default is true.
      '';
    };

    system.defaults.NSGlobalDomain.NSAutomaticQuoteSubstitutionEnabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to enable smart quote substitution.  The default is true.
      '';
    };

    system.defaults.NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to enable automatic spelling correction.  The default is true.
      '';
    };

    system.defaults.NSGlobalDomain.NSAutomaticWindowAnimationsEnabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to animate opening and closing of windows and popovers.  The default is true.
      '';
    };

    system.defaults.NSGlobalDomain.NSDisableAutomaticTermination = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to disable the automatic termination of inactive apps.
      '';
    };

    system.defaults.NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to save new documents to iCloud by default.  The default is true.
      '';
    };

    system.defaults.NSGlobalDomain.AppleWindowTabbingMode = mkOption {
      type = types.nullOr (types.enum [ "manual" "always" "fullscreen" ]);
      default = null;
      description = lib.mdDoc ''
        Sets the window tabbing when opening a new document: 'manual', 'always', or 'fullscreen'.  The default is 'fullscreen'.
      '';
    };

    system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to use expanded save panel by default.  The default is false.
      '';
    };

    system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode2 = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to use expanded save panel by default.  The default is false.
      '';
    };

    system.defaults.NSGlobalDomain.NSTableViewDefaultSizeMode = mkOption {
      type = types.nullOr (types.enum [ 1 2 3 ]);
      default = null;
      description = lib.mdDoc ''
        Sets the size of the finder sidebar icons: 1 (small), 2 (medium) or 3 (large). The default is 3.
      '';
    };

    system.defaults.NSGlobalDomain.NSTextShowsControlCharacters = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to display ASCII control characters using caret notation in standard text views. The default is false.
      '';
    };

    system.defaults.NSGlobalDomain.NSUseAnimatedFocusRing = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to enable the focus ring animation. The default is true.
      '';
    };

    system.defaults.NSGlobalDomain.NSScrollAnimationEnabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to enable smooth scrolling. The default is true.
      '';
    };

    system.defaults.NSGlobalDomain.NSWindowResizeTime = mkOption {
      type = types.nullOr floatWithDeprecationError;
      default = null;
      example = 0.20;
      description = lib.mdDoc ''
        Sets the speed speed of window resizing. The default is given in the example.
      '';
    };

    system.defaults.NSGlobalDomain.NSWindowShouldDragOnGesture = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to enable moving window by holding anywhere on it like on Linux. The default is false.
      '';
    };

    system.defaults.NSGlobalDomain.InitialKeyRepeat = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = lib.mdDoc ''
        Apple menu > System Preferences > Keyboard

        If you press and hold certain keyboard keys when in a text area, the key’s character begins to repeat.
        For example, the Delete key continues to remove text for as long as you hold it down.

        This sets how long you must hold down the key before it starts repeating.
      '';
    };

    system.defaults.NSGlobalDomain.KeyRepeat = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = lib.mdDoc ''
        Apple menu > System Preferences > Keyboard

        If you press and hold certain keyboard keys when in a text area, the key’s character begins to repeat.
        For example, the Delete key continues to remove text for as long as you hold it down.

        This sets how fast it repeats once it starts.
      '';
    };

    system.defaults.NSGlobalDomain.PMPrintingExpandedStateForPrint = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to use the expanded print panel by default. The default is false.
      '';
    };

    system.defaults.NSGlobalDomain.PMPrintingExpandedStateForPrint2 = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to use the expanded print panel by default. The default is false.
      '';
    };

    system.defaults.NSGlobalDomain."com.apple.keyboard.fnState" = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Use F1, F2, etc. keys as standard function keys.
      '';
    };

    system.defaults.NSGlobalDomain."com.apple.mouse.tapBehavior" = mkOption {
      type = types.nullOr (types.enum [ 1 ]);
      default = null;
      description = lib.mdDoc ''
        Configures the trackpad tap behavior.  Mode 1 enables tap to click.
      '';
    };

    system.defaults.NSGlobalDomain."com.apple.sound.beep.volume" = mkOption {
      type = types.nullOr floatWithDeprecationError;
      default = null;
      description = lib.mdDoc ''
        Apple menu > System Preferences > Sound

        Sets the beep/alert volume level from 0.000 (muted) to 1.000 (100% volume).

        75% = 0.7788008

        50% = 0.6065307

        25% = 0.4723665
      '';
    };

    system.defaults.NSGlobalDomain."com.apple.sound.beep.feedback" = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = lib.mdDoc ''
        Apple menu > System Preferences > Sound

        Make a feedback sound when the system volume changed. This setting accepts
        the integers 0 or 1. Defaults to 1.
      '';
    };

    system.defaults.NSGlobalDomain."com.apple.trackpad.enableSecondaryClick" = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to enable trackpad secondary click.  The default is true.
      '';
    };

    system.defaults.NSGlobalDomain."com.apple.trackpad.trackpadCornerClickBehavior" = mkOption {
      type = types.nullOr (types.enum [ 1 ]);
      default = null;
      description = lib.mdDoc ''
        Configures the trackpad corner click behavior.  Mode 1 enables right click.
      '';
    };

    system.defaults.NSGlobalDomain."com.apple.trackpad.scaling" = mkOption {
      type = types.nullOr floatWithDeprecationError;
      default = null;
      description = lib.mdDoc ''
        Configures the trackpad tracking speed (0 to 3).  The default is "1".
      '';
    };

    system.defaults.NSGlobalDomain."com.apple.springing.enabled" = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to enable spring loading (expose) for directories.
      '';
    };

    system.defaults.NSGlobalDomain."com.apple.springing.delay" = mkOption {
      type = types.nullOr floatWithDeprecationError;
      default = null;
      example = 1.0;
      description = lib.mdDoc ''
        Set the spring loading delay for directories. The default is given in the example.
      '';
    };

    system.defaults.NSGlobalDomain."com.apple.swipescrolldirection" = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to enable "Natural" scrolling direction.  The default is true.
      '';
    };

    system.defaults.NSGlobalDomain.AppleMeasurementUnits = mkOption {
      type = types.nullOr (types.enum [ "Centimeters" "Inches" ]);
      default = null;
      description = lib.mdDoc ''
        Whether to use centimeters (metric) or inches (US, UK) as the measurement unit.  The default is based on region settings.
      '';
    };

    system.defaults.NSGlobalDomain.AppleMetricUnits = mkOption {
      type = types.nullOr (types.enum [ 0 1 ]);
      default = null;
      description = lib.mdDoc ''
        Whether to use the metric system.  The default is based on region settings.
      '';
    };

    system.defaults.NSGlobalDomain.AppleTemperatureUnit = mkOption {
      type = types.nullOr (types.enum [ "Celsius" "Fahrenheit" ]);
      default = null;
      description = lib.mdDoc ''
        Whether to use Celsius or Fahrenheit.  The default is based on region settings.
      '';
    };

    system.defaults.NSGlobalDomain.AppleICUForce24HourTime = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to use 24-hour or 12-hour time.  The default is based on region settings.
      '';
    };

    system.defaults.NSGlobalDomain._HIHideMenuBar = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to autohide the menu bar.  The default is false.
      '';
    };

  };

}
