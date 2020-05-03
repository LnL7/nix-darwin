{ config, lib, ... }:

with lib;

{
  options = {

    system.defaults.screencapture.location = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
          The filesystem path to which screencaptures should be written.
        '';
    };

    system.defaults.screencapture.disable-shadow = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
          Disable drop shadow border around screencaptures. The default is false;
        '';
    };
  };
}
