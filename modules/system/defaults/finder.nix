{ config, lib, ... }:

with lib;

{
  options = {

    system.defaults.finder.AppleShowAllExtensions = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to always show file extensions.  The default is false.
      '';
    };

    system.defaults.finder.CreateDesktop = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to show icons on the desktop or not. The default is true.
      '';
    };

    system.defaults.finder.QuitMenuItem = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to allow quitting of the Finder.  The default is false.
      '';
    };

    system.defaults.finder._FXShowPosixPathInTitle = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to show the full POSIX filepath in the window title.  The default is false.
      '';
    };

    system.defaults.finder.FXEnableExtensionChangeWarning = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to show warnings when change the file extension of files.  The default is true.
      '';
    };

  };
}
