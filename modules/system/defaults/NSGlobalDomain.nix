{ config, lib, ... }:

with lib;

{
  options = {

    system.defaults.NSGlobalDomain.InitialKeyRepeat = mkOption {
      type = types.nullOr types.int;
      default = null;
    };

    system.defaults.NSGlobalDomain.KeyRepeat = mkOption {
      type = types.nullOr types.int;
      default = null;
    };

  };
}
