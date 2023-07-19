{ config, lib, ... }:

with lib;

{
  options = {

    system.defaults.LaunchServices.LSQuarantine = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to enable quarantine for downloaded applications.  The default is true.
      '';
    };

  };
}
