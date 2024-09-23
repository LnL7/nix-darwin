# Based off:
# https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/misc/nix-optimise.nix
# When making changes please try to keep it in sync.
{ config, lib, ... }:


let
  inherit (lib)
    mkIf
    mkOption
    mkRemovedOptionModule
    optionalString
    types
    ;

  cfg = config.nix.optimise;
  launchdTypes = import ../../launchd/types.nix { inherit config lib; };
in

{
  imports = [
    (mkRemovedOptionModule [ "nix" "optimise" "dates" ] "Use `nix.optimise.interval` instead.")
  ];

  ###### interface

  options = {

    nix.optimise = {

      automatic = mkOption {
        type = types.bool;
        default = false;
        description = "Automatically run the nix store optimiser at a specific time.";
      };

      # Not in NixOS module
      user = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "User that runs the store optimisation.";
      };

      interval = mkOption {
        type = launchdTypes.StartCalendarInterval;
        default = [{ Weekday = 7; Hour = 4; Minute = 15; }];
        description = ''
          The calendar interval at which the optimiser will run.
          See the {option}`serviceConfig.StartCalendarInterval` option of
          the {option}`launchd` module for more info.
        '';
      };

    };

  };


  ###### implementation

  config = mkIf cfg.automatic {

    launchd.daemons.nix-optimise = {
      environment.NIX_REMOTE = optionalString config.nix.useDaemon "daemon";
      command = "${lib.getExe' config.nix.package "nix-store"} --optimise";
      serviceConfig = {
        RunAtLoad = false;
        StartCalendarInterval = cfg.interval;
        UserName = cfg.user;
      };
    };

  };
}
