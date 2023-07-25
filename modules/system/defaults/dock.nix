{ config, lib, ... }:

with lib;

let
  # Should only be used with options that previously used floats defined as strings.
  inherit (config.lib.defaults.types) floatWithDeprecationError;
in {
  options = {

    system.defaults.dock.appswitcher-all-displays = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to display the appswitcher on all displays or only the main one. The default is false.
      '';
    };

    system.defaults.dock.autohide = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to automatically hide and show the dock.  The default is false.
      '';
    };

    system.defaults.dock.autohide-delay = mkOption {
      type = types.nullOr floatWithDeprecationError;
      default = null;
      example = 0.24;
      description = lib.mdDoc ''
        Sets the speed of the autohide delay. The default is given in the example.
      '';
    };

    system.defaults.dock.autohide-time-modifier = mkOption {
      type = types.nullOr floatWithDeprecationError;
      default = null;
      example = 1.0;
      description = lib.mdDoc ''
        Sets the speed of the animation when hiding/showing the Dock. The default is given in the example.
      '';
    };

    system.defaults.dock.dashboard-in-overlay = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to hide Dashboard as a Space. The default is false.
      '';
    };

    system.defaults.dock.enable-spring-load-actions-on-all-items = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Enable spring loading for all Dock items. The default is false.
      '';
    };

    system.defaults.dock.expose-animation-duration = mkOption {
      type = types.nullOr floatWithDeprecationError;
      default = null;
      example = 1.0;
      description = lib.mdDoc ''
        Sets the speed of the Mission Control animations. The default is given in the example.
      '';
    };

    system.defaults.dock.expose-group-by-app = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to group windows by application in Mission Control's Exposé. The default is true.
      '';
    };

    system.defaults.dock.launchanim = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Animate opening applications from the Dock. The default is true.
      '';
    };

    system.defaults.dock.mineffect = mkOption {
      type = types.nullOr (types.enum [ "genie" "suck" "scale" ]);
      default = null;
      description = lib.mdDoc ''
        Set the minimize/maximize window effect. The default is genie.
      '';
    };

    system.defaults.dock.minimize-to-application = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to minimize windows into their application icon.  The default is false.
      '';
    };

    system.defaults.dock.mouse-over-hilite-stack = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Enable highlight hover effect for the grid view of a stack in the Dock.
      '';
    };

    system.defaults.dock.mru-spaces = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to automatically rearrange spaces based on most recent use.  The default is true.
      '';
    };

    system.defaults.dock.orientation = mkOption {
      type = types.nullOr (types.enum [ "bottom" "left" "right" ]);
      default = null;
      description = lib.mdDoc ''
        Position of the dock on screen.  The default is "bottom".
      '';
    };

    system.defaults.dock.show-process-indicators = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Show indicator lights for open applications in the Dock. The default is true.
      '';
    };

    system.defaults.dock.showhidden = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to make icons of hidden applications tranclucent.  The default is false.
      '';
    };

    system.defaults.dock.show-recents = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Show recent applications in the dock. The default is true.
      '';
    };

    system.defaults.dock.static-only = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Show only open applications in the Dock. The default is false.
      '';
    };

    system.defaults.dock.tilesize = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = lib.mdDoc ''
        Size of the icons in the dock.  The default is 64.
      '';
    };

    system.defaults.dock.magnification = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Magnify icon on hover. The default is false.
      '';
    };

    system.defaults.dock.largesize = mkOption {
      type = types.nullOr (types.ints.between 16 128);
      default = null;
      description = lib.mdDoc ''
        Magnified icon size on hover. The default is 16.
      '';
    };
   

    system.defaults.dock.wvous-tl-corner = mkOption {
      type = types.nullOr types.ints.positive;
      default = null;
      description = lib.mdDoc ''
        Hot corner action for top left corner. Valid values include:

        * `1`: Disabled
        * `2`: Mission Control
        * `3`: Application Windows
        * `4`: Desktop
        * `5`: Start Screen Saver
        * `6`: Disable Screen Saver
        * `7`: Dashboard
        * `10`: Put Display to Sleep
        * `11`: Launchpad
        * `12`: Notification Center
        * `13`: Lock Screen
        * `14`: Quick Note
      '';
    };

    system.defaults.dock.wvous-bl-corner = mkOption {
      type = types.nullOr types.ints.positive;
      default = null;
      description = lib.mdDoc ''
        Hot corner action for bottom left corner. Valid values include:

        * `1`: Disabled
        * `2`: Mission Control
        * `3`: Application Windows
        * `4`: Desktop
        * `5`: Start Screen Saver
        * `6`: Disable Screen Saver
        * `7`: Dashboard
        * `10`: Put Display to Sleep
        * `11`: Launchpad
        * `12`: Notification Center
        * `13`: Lock Screen
        * `14`: Quick Note
      '';
    };

    system.defaults.dock.wvous-tr-corner = mkOption {
      type = types.nullOr types.ints.positive;
      default = null;
      description = lib.mdDoc ''
        Hot corner action for top right corner. Valid values include:

        * `1`: Disabled
        * `2`: Mission Control
        * `3`: Application Windows
        * `4`: Desktop
        * `5`: Start Screen Saver
        * `6`: Disable Screen Saver
        * `7`: Dashboard
        * `10`: Put Display to Sleep
        * `11`: Launchpad
        * `12`: Notification Center
        * `13`: Lock Screen
        * `14`: Quick Note
      '';
    };

    system.defaults.dock.wvous-br-corner = mkOption {
      type = types.nullOr types.ints.positive;
      default = null;
      description = lib.mdDoc ''
        Hot corner action for bottom right corner. Valid values include:

        * `1`: Disabled
        * `2`: Mission Control
        * `3`: Application Windows
        * `4`: Desktop
        * `5`: Start Screen Saver
        * `6`: Disable Screen Saver
        * `7`: Dashboard
        * `10`: Put Display to Sleep
        * `11`: Launchpad
        * `12`: Notification Center
        * `13`: Lock Screen
        * `14`: Quick Note
      '';
    };

    };
}
