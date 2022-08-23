# Based off: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/misc/nix-gc.nix
# When making changes please try to keep it in sync.
{ config, lib, ... }:

with lib;

let
  cfg = config.nix.gc;
in

{
  imports = [
    (mkRemovedOptionModule [ "nix" "gc" "dates" ] "Use `nix.gc.interval` instead.")
    (mkRemovedOptionModule [ "nix" "gc" "randomizedDelaySec" ] "No `nix-darwin` equivilant to this NixOS option.")
    (mkRemovedOptionModule [ "nix" "gc" "persistent" ] "No `nix-darwin` equivilant to this NixOS option.")
  ];

  ###### interface

  options = {

    nix.gc = {

      automatic = mkOption {
        default = false;
        type = types.bool;
        description = "Automatically run the garbage collector at a specific time.";
      };

      # Not in NixOS module
      user = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "User that runs the garbage collector.";
      };

      interval = mkOption {
        type = types.attrs;
        default = { Hour = 3; Minute = 15; };
        description = "The time interval at which the garbage collector will run.";
      };

      options = mkOption {
        default = "";
        example = "--max-freed $((64 * 1024**3))";
        type = types.str;
        description = ''
          Options given to <filename>nix-collect-garbage</filename> when the
          garbage collector is run automatically.
        '';
      };

    };

  };


  ###### implementation

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
