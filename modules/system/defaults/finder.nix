{ config, lib, ... }:

with lib;

{
  options = {

    system.defaults.finder.AppleShowAllFiles = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to always show hidden files. The default is false.
      '';
    };

    system.defaults.finder.ShowStatusBar = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Show status bar at bottom of finder windows with item/disk space stats. The default is false.
      '';
    };

    system.defaults.finder.ShowPathbar = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Show path breadcrumbs in finder windows. The default is false.
      '';
    };

    system.defaults.finder.FXDefaultSearchScope = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = lib.mdDoc ''
        Change the default search scope. Use "SCcf" to default to current folder.
        The default is unset ("This Mac").
      '';
    };

    system.defaults.finder.FXPreferredViewStyle = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = lib.mdDoc ''
        Change the default finder view.
        "icnv" = Icon view, "Nlsv" = List view, "clmv" = Column View, "Flwv" = Gallery View
        The default is icnv.
      '';
    };

    system.defaults.finder.AppleShowAllExtensions = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to always show file extensions.  The default is false.
      '';
    };

    system.defaults.finder.CreateDesktop = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to show icons on the desktop or not. The default is true.
      '';
    };

    system.defaults.finder.QuitMenuItem = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to allow quitting of the Finder.  The default is false.
      '';
    };

    system.defaults.finder._FXShowPosixPathInTitle = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to show the full POSIX filepath in the window title.  The default is false.
      '';
    };

    system.defaults.finder.FXEnableExtensionChangeWarning = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to show warnings when change the file extension of files.  The default is true.
      '';
    };

  };
}
