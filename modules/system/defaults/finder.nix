{ config, lib, ... }:

with lib;

{
  options = {

    system.defaults.finder.AppleShowAllFiles = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to always show hidden files. The default is false.
      '';
    };

    system.defaults.finder.ShowStatusBar = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Show status bar at bottom of finder windows with item/disk space stats. The default is false.
      '';
    };

    system.defaults.finder.ShowPathbar = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Show path breadcrumbs in finder windows. The default is false.
      '';
    };

    system.defaults.finder.FXDefaultSearchScope = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Change the default search scope. Use "SCcf" to default to current folder.
        The default is unset ("This Mac").
      '';
    };

    system.defaults.finder.FXRemoveOldTrashItems = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Remove items in the bin after 30 days.
        The default is false.
      '';
    };

    system.defaults.finder.FXPreferredViewStyle = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Change the default finder view.
        "icnv" = Icon view, "Nlsv" = List view, "clmv" = Column View, "Flwv" = Gallery View
        The default is icnv.
      '';
    };

    system.defaults.finder.AppleShowAllExtensions = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to always show file extensions. The default is false.
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
        Whether to allow quitting of the Finder. The default is false.
      '';
    };

    system.defaults.finder.ShowExternalHardDrivesOnDesktop = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to show external disks on desktop. The default is true.
      '';
    };

    system.defaults.finder.ShowHardDrivesOnDesktop = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to show hard disks on desktop. The default is false.
      '';
    };

    system.defaults.finder.ShowMountedServersOnDesktop = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to show connected servers on desktop. The default is false.
      '';
    };

    system.defaults.finder.ShowRemovableMediaOnDesktop = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to show removable media (CDs, DVDs and iPods) on desktop. The default is true.
      '';
    };

    system.defaults.finder._FXShowPosixPathInTitle = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to show the full POSIX filepath in the window title. The default is false.
      '';
    };

    system.defaults.finder._FXSortFoldersFirst = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Keep folders on top when sorting by name. The default is false.
      '';
    };

    system.defaults.finder._FXSortFoldersFirstOnDesktop = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Keep folders on top when sorting by name on the desktop. The default is false.
      '';
    };

    system.defaults.finder.FXEnableExtensionChangeWarning = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to show warnings when change the file extension of files. The default is true.
      '';
    };

  };
}
