{ config, lib, ... }:

with lib;

{
  options = {

    system.defaults.clock.IsAnalog = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Show an analog clock instead of a digital one. Default is null.
      '';
    };

    system.defaults.clock.Show24Hour = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Show a 24-hour clock, instead of a 12-hour clock. Default is null.
      '';
    };

    system.defaults.clock.ShowAMPM = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Show the AM/PM label. Useful if Show24Hour is false. Default is null.
      '';
    };

    system.defaults.clock.ShowDayOfMonth = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Show the day of the month. Default is null.
      '';
    };

    system.defaults.clock.ShowDayOfWeek = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Show the day of the week. Default is null.
      '';
    };

    system.defaults.clock.ShowDate = mkOption {
      type = types.nullOr (types.enum [ 0 1 2 ]);
      default = null;
      description = ''
        Show the full date. Default is null.

        0 = Show the date
        1 = Don't show
        2 = Don't show

        TODO: I don't know what the difference is between 1 and 2.
      '';
    };

    system.defaults.clock.ShowSeconds = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Show the clock with second precision, instead of minutes. Default is null.
      '';
    };

  };
}
