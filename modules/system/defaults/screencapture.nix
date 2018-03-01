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
  };
}
