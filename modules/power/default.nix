{ config, lib, ... }:

let
  cfg = config.power;

  types = lib.types;

  onOff = cond: if cond then "on" else "off";
in

{
  options = {
    power.restartAfterPowerFailure = lib.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to restart the computer after a power failure.

        Option is not supported on all devices.
      '';
    };

    power.restartAfterFreeze = lib.mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = ''
        Whether to restart the computer after a system freeze.
      '';
    };
  };

  config = {

    system.activationScripts.power.text = ''
      echo "configuring power..." >&2

      ${lib.optionalString (cfg.restartAfterPowerFailure != null) ''
        systemsetup -setRestartPowerFailure \
          '${onOff cfg.restartAfterPowerFailure}' &> /dev/null
      ''}

      ${lib.optionalString (cfg.restartAfterFreeze != null) ''
        systemsetup -setRestartFreeze \
          '${onOff cfg.restartAfterFreeze}' &> /dev/null
      ''}
    '';

  };
}
