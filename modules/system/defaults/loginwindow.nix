{ config, lib, ... }:

with lib;

{
  options = {
    system.defaults.loginwindow.SHOWFULLNAME = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        # Apple menu > System Preferences > Users and Groups > Login Options
        Displays login window as a name and password field instead of a list of users.
        Default is false.
      '';
    };

    system.defaults.loginwindow.autoLoginUser = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        # Apple menu > System Preferences > Users and Groups > Login Options
        Auto login the supplied user on boot. Default is Off.
      '';
    };

    system.defaults.loginwindow.GuestEnabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        # Apple menu > System Preferences > Users and Groups > Login Options
        Allow users to login to the machine as guests using the Guest account. Default is true.
      '';
    };

    system.defaults.loginwindow.LoginwindowText = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        Text to be shown on the login window. Default "\\U03bb".
      '';
    };

    system.defaults.loginwindow.ShutDownDisabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        # Apple menu > System Preferences > Users and Groups > Login Options
        Hides the Shut Down button on the login screen. Default is false.
      '';
    };

    system.defaults.loginwindow.SleepDisabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        # Apple menu > System Preferences > Users and Groups > Login Options
        Hides the Sleep button on the login screen. Default is false.
      '';
    };

    system.defaults.loginwindow.RestartDisabled = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        # Apple menu > System Preferences > Users and Groups > Login Options
        Hides the Restart button on the login screen. Default is false.
      '';
    };

    system.defaults.loginwindow.ShutDownDisabledWhileLoggedIn = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        # Apple menu > System Preferences > Users and Groups > Login Options
        Disables the "Shutdown" option when users are logged in. Default is false.
      '';
    };

    system.defaults.loginwindow.PowerOffDisabledWhileLoggedIn = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        # Apple menu > System Preferences > Users and Groups > Login Options
        If set to true, the Power Off menu item will be disabled when the user is logged in. Default is false.
      '';
    };

    system.defaults.loginwindow.RestartDisabledWhileLoggedIn = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        # Apple menu > System Preferences > Users and Groups > Login Options
        Disables the “Restart” option when users are logged in. Default is false.
      '';
    };

    system.defaults.loginwindow.DisableConsoleAccess = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Disables the ability for a user to access the console by typing “>console”
        for a username at the login window. Default is false.
      '';
    };
  };
}
