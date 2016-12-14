{ config, lib, ... }:

with lib;

{
  options = {

    system.defaults.trackpad.Clicking = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to enable trackpad tap to click.  The default is false.
      '';
    };

    system.defaults.trackpad.TrackpadRightClick = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to enable trackpad right click.  The default is false.
      '';
    };

  };
}
