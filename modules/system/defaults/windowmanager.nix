{ config, lib, ... }:

with lib;

{
  options = {
    system.defaults.windowmanager.GloballyEnabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        # Apple menu > System Settings > Dekstop and Dock > Stage Manager
        Stage Manager arranges your recent windows into a single strip for reduced clutter and quick access. Default is false.
      '';
    };

    system.defaults.windowmanager.GloballyEnabledEver = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        # Apple menu > System Settings > Dekstop and Dock > Stage Manager
        Default is true.
      '';
    };

    system.defaults.windowmanager.AutoHide = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        # Apple menu > System Settings > Dekstop and Dock > Stage Manager
        Do not show Recent Apps. Default is false.
      '';
    };

    system.defaults.windowmanager.HideDesktop = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        # Apple menu > System Settings > Dekstop and Dock > Stage Manager
        Hide dekstop items. Default is false.
      '';
    };
  };
}
