{ config, lib, ... }:

with lib;

{
  options = {
    system.defaults.smb.NetBIOSName = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Hostname to use for NetBIOS.";
    };

    system.defaults.smb.ServerDescription = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Hostname to use for sharing services.";
    };
  };
}
