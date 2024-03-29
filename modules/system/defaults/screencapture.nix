{ config, lib, ... }:

with lib;

{
  options = {

    system.defaults.screencapture.location = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = lib.mdDoc ''
          The filesystem path to which screencaptures should be written.
        '';
    };

    system.defaults.screencapture.type = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = lib.mdDoc ''
          The image format to use, such as "jpg".
        '';
    };

    system.defaults.screencapture.disable-shadow = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
          Disable drop shadow border around screencaptures. The default is false.
        '';
    };
  };
}
