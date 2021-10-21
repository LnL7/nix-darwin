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

    system.defaults.dock.autohide = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to automatically hide and show the dock.  The default is false.
      '';
    };

    system.defaults.dock.autohide-delay = mkOption {
      type = types.nullOr float;
      default = null;
      example = "0.24";
      description = ''
        Sets the speed of the autohide delay. The default is given in the example.
      '';
    };

    system.defaults.dock.autohide-time-modifier = mkOption {
      type = types.nullOr float;
      default = null;
      example = "1.0";
      description = ''
        Sets the speed of the animation when hiding/showing the Dock. The default is given in the example.
      '';
    };

    system.defaults.dock.dashboard-in-overlay = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to hide Dashboard as a Space. The default is false.
      '';
    };

    system.defaults.dock.enable-spring-load-actions-on-all-items = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Enable spring loading for all Dock items. The default is false.
      '';
    };

    system.defaults.dock.expose-animation-duration = mkOption {
      type = types.nullOr float;
      default = null;
      example = "1.0";
      description = ''
        Sets the speed of the Mission Control animations. The default is given in the example.
      '';
    };

    system.defaults.dock.expose-group-by-app = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to group windows by application in Mission Control's Exposé. The default is true.
      '';
    };

    system.defaults.dock.launchanim = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Animate opening applications from the Dock. The default is true.
      '';
    };

    system.defaults.dock.mineffect = mkOption {
      type = types.nullOr (types.enum [ "genie" "suck" "scale" ]);
      default = null;
      description = ''
        Set the minimize/maximize window effect. The default is genie.
      '';
    };

    system.defaults.dock.minimize-to-application = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to minimize windows into their application icon.  The default is false.
      '';
    };

    system.defaults.dock.mouse-over-hilite-stack = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Enable highlight hover effect for the grid view of a stack in the Dock.
      '';
    };

    system.defaults.dock.mru-spaces = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to automatically rearrange spaces based on most recent use.  The default is true.
      '';
    };

    system.defaults.dock.orientation = mkOption {
      type = types.nullOr (types.enum [ "bottom" "left" "right" ]);
      default = null;
      description = ''
        Position of the dock on screen.  The default is "bottom".
      '';
    };

    system.defaults.dock.show-process-indicators = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Show indicator lights for open applications in the Dock. The default is true.
      '';
    };

    system.defaults.dock.showhidden = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to make icons of hidden applications tranclucent.  The default is false.
      '';
    };

    system.defaults.dock.show-recents = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Show recent applications in the dock. The default is true.
      '';
    };

    system.defaults.dock.static-only = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Show only open applications in the Dock. The default is false.
      '';
    };

    system.defaults.dock.tilesize = mkOption {
      type = types.nullOr types.int;
      default = null;
      description = ''
        Size of the icons in the dock.  The default is 64.
      '';
    };

    };
}
