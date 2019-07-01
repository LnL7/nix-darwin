{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.nix.gc;
in

{
  options = {
    nix.gc.automatic = mkOption {
      type = types.bool;
      default = false;
      description = "Automatically run the garbage collector at a specific time.";
    };

    nix.gc.user = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "User that runs the garbage collector.";
    };

    nix.gc.interval = mkOption {
      type = types.attrs;
      default = { Hour = 3; Minute = 15; };
      description = "The time interval at which the garbage collector will run.";
    };

    nix.gc.options = mkOption {
      type = types.str;
      default = "";
      example = "--max-freed $((64 * 1024**3))";
      description = ''
        Options given to <filename>nix-collect-garbage</filename> when the
        garbage collector is run automatically.
      '';
    };
  };

  config = mkIf cfg.automatic {

    launchd.daemons.nix-gc = {
      command = "${config.nix.package}/bin/nix-collect-garbage ${cfg.options}";
      environment.NIX_REMOTE = optionalString config.nix.useDaemon "daemon";
      serviceConfig.RunAtLoad = false;
      serviceConfig.StartCalendarInterval = [ cfg.interval ];
      serviceConfig.UserName = cfg.user;
    };

  };
}
