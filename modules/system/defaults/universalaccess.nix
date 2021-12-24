{ config, lib, ... }:

with lib;

{
  options = {

    system.defaults.universalaccess.reduceTransparency = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Disable transparency in the menu bar and elsewhere.
        Requires macOS Yosemite or later.
        The default is false.
      '';
    };

    system.defaults.universalaccess.closeViewScrollWheelToggle = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Use scroll gesture with the Ctrl (^) modifier key to zoom.
        The default is false.
      '';
    };

    system.defaults.universalaccess.closeViewZoomFollowsFocus = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Follow the keyboard focus while zoomed in.
        Without setting `closeViewScrollWheelToggle` this has no effect.
        The default is false.
      '';
    };

  };
}
