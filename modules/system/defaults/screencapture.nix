{ config, lib, ... }:

with lib;

{
  options = {

    system.defaults.screencapture.location = mkOption {
      type = types.string;
      default = "~/Desktop";
      description = ''
          The filesystem path to which screencaptures should be written.
        '';
    };
  };
}
