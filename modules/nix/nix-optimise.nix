{ config, lib, ...}:
with lib;

let
  cfg = config.nix.optimise;
in

{
  options = {
    nix.optimise = {
      enable = mkOption {
        default = false;
        type = types.bool;
        description = lib.mdDoc "Automatically run the nix store optimiser at a specific time.";
      };
      periodSeconds = mkOption {
        default = 60 * 60 * 8;
        type = types.int;
        description = lib.mdDoc "Interval between runs of the optimizer in seconds.";
      };
    };
  };

  config = {
    launchd.daemons.nix-optimise.serviceConfig = {
      ProgramArguments = ["${config.nix.package}/bin/nix-store" "--optimise"];
      StartInterval = cfg.periodSeconds;
    };
  };
}
