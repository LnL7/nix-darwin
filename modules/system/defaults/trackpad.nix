{ config, lib, ... }:

with lib;

{
  options = {

    system.defaults.trackpad.Clicking = mkOption {
      type = types.nullOr types.bool;
      default = null;
    };

  };
}
