{ config, lib, ... }:

with lib;

let
  cfg = config.power.sleep;

  onOff = cond: if cond then "on" else "off";
in

{
  options = {
    power.sleep.computer = mkOption {
      type = types.nullOr (types.either types.ints.unsigned (types.enum ["never"]));
      default = null;
      example = "never";
      description = lib.mdDoc ''
        Amount of idle time (in minutes) until the computer sleeps.

        `0` and `"never"` both disables computer sleeping.

        The system might not be considered idle before connected displays sleep, as
        per the `power.sleep.display` option.
      '';
    };

    power.sleep.display = mkOption {
      type = types.nullOr (types.either types.ints.unsigned (types.enum ["never"]));
      default = null;
      example = "never";
      description = lib.mdDoc ''
        Amount of idle time (in minutes) until displays sleep.

        `0` and `"never"` both disables display sleeping.
      '';
    };

    power.sleep.harddisk = mkOption {
      type = types.nullOr (types.either types.ints.unsigned (types.enum ["never"]));
      default = null;
      example = "never";
      description = lib.mdDoc ''
        Amount of idle time (in minutes) until hard disks sleep.

        `0` and `"never"` both disables hard disk sleeping.
      '';
    };

    power.sleep.allowSleepByPowerButton = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether the power button can sleep the computer.
      '';
    };
  };

  config = {

    system.activationScripts.sleep.text = ''
      ${optionalString (cfg.computer != null) ''
        systemsetup -setComputerSleep '${toString cfg.computer}' &> /dev/null
      ''}

      ${optionalString (cfg.display != null) ''
        systemsetup -setDisplaySleep '${toString cfg.display}' &> /dev/null
      ''}

      ${optionalString (cfg.harddisk != null) ''
        systemsetup -setHardDiskSleep '${toString cfg.harddisk}' &> /dev/null
      ''}

      ${optionalString (cfg.allowSleepByPowerButton != null) ''
        systemsetup -setAllowPowerButtonToSleepComputer \
          '${onOff cfg.allowSleepByPowerButton}' &> /dev/null
      ''}
    '';

  };
}
