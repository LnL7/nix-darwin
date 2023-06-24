{ config, lib, ... }:

with lib;

{
  options = {

    system.defaults.menuExtraClock.IsAnalog = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Show an analog clock instead of a digital one. Default is null.
      '';
    };

    system.defaults.menuExtraClock.Show24Hour = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Show a 24-hour clock, instead of a 12-hour clock. Default is null.
      '';
    };

    system.defaults.menuExtraClock.ShowAMPM = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Show the AM/PM label. Useful if Show24Hour is false. Default is null.
      '';
    };

    system.defaults.menuExtraClock.ShowDayOfMonth = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Show the day of the month. Default is null.
      '';
    };

    system.defaults.menuExtraClock.ShowDayOfWeek = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Show the day of the week. Default is null.
      '';
    };

    system.defaults.menuExtraClock.ShowDate = mkOption {
      type = types.nullOr (types.enum [ 0 1 2 ]);
      default = null;
      description = lib.mdDoc ''
        Show the full date. Default is null.

        0 = Show the date
        1 = Don't show
        2 = Don't show

        TODO: I don't know what the difference is between 1 and 2.
      '';
    };

    system.defaults.menuExtraClock.ShowSeconds = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Show the clock with second precision, instead of minutes. Default is null.
      '';
    };

  };
}
