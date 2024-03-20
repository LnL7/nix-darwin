{ config, lib, ... }:

with lib;

let
  cfg = config.power;

  onOff = cond: if cond then "On" else "Off";
in

{
  options = {
    power.restartAfterPowerFailure = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to restart the computer after a power failure.
      '';
    };

    power.restartAfterFreeze = mkOption {
      type = types.nullOr types.bool;
      default = null;
      description = lib.mdDoc ''
        Whether to restart the computer after a system freeze.
      '';
    };
  };

  config = {

    system.activationScripts.power.text = ''
      echo "configuring power..." >&2

      ${optionalString (cfg.restartAfterPowerFailure != null) ''
        systemsetup -setRestartPowerFailure \
          '${onOff cfg.restartAfterPowerFailure}' &> /dev/null
      ''}

      ${optionalString (cfg.restartAfterFreeze != null) ''
        systemsetup -setRestartFreeze \
          '${onOff cfg.restartAfterFreeze}' &> /dev/null
      ''}
    '';

  };
}
