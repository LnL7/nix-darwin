{ config, lib, ... }:

with lib;

{
  options = {

    system.defaults.dock.autohide = mkOption {
      type = types.nullOr types.bool;
      default = null;
    };

  };
}
