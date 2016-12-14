{ config, lib, ... }:

with lib;

{
  options = {

    system.defaults.LaunchServices.LSQuarantine = mkOption {
      type = types.nullOr types.bool;
      default = null;
    };

  };
}
