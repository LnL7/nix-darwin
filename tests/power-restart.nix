{ config, pkgs, ... }:

{
  power.restartAfterPowerFailure = true;
  power.restartAfterFreeze = true;

  test = ''
    echo checking restart power settings in /activate >&2
    grep "systemsetup -setRestartPowerFailure 'on'" ${config.out}/activate
    grep "systemsetup -setRestartFreeze 'on'" ${config.out}/activate
  '';
}
