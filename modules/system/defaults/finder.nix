{ config, lib, ... }:

with lib;

{
  options = {

    system.defaults.finder.AppleShowAllExtensions = mkOption {
      type = types.nullOr types.bool;
      default = null;
    };

  };
}
