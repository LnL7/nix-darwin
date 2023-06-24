{ config, lib, ... }:

with lib;

{
  options = {

    system.defaults.universalaccess.mouseDriverCursorSize = mkOption {
      type = types.nullOr types.float;
      default = null;
      example = 1.5;
      description = lib.mdDoc ''
        Set the size of cursor. 1 for normal, 4 for maximum.
        The default is 1.
      '';
    };

    system.defaults.universalaccess.reduceTransparency = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Disable transparency in the menu bar and elsewhere.
        Requires macOS Yosemite or later.
        The default is false.
      '';
    };

    system.defaults.universalaccess.closeViewScrollWheelToggle = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Use scroll gesture with the Ctrl (^) modifier key to zoom.
        The default is false.
      '';
    };

    system.defaults.universalaccess.closeViewZoomFollowsFocus = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Follow the keyboard focus while zoomed in.
        Without setting `closeViewScrollWheelToggle` this has no effect.
        The default is false.
      '';
    };

  };
}
