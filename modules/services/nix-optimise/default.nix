# Based off:
# https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/misc/nix-optimise.nix
# When making changes please try to keep it in sync.
{ config, lib, ... }:


let
  inherit (lib)
    mdDoc
    mkIf
    mkOption
    mkRemovedOptionModule
    optionalString
    types
    ;

  cfg = config.nix.optimise;
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
        description = mdDoc "Automatically run the nix store optimiser at a specific time.";
      };

      # Not in NixOS module
      user = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = mdDoc "User that runs the store optimisation.";
      };

      interval = mkOption {
        type = types.attrs;
        default = { Hour = 3; Minute = 15; };
        description = mdDoc "The time interval at which the optimiser will run.";
      };

    };

  };


  ###### implementation

  config = mkIf cfg.automatic {

    launchd.daemons.nix-optimise = {
      environment.NIX_REMOTE = optionalString config.nix.useDaemon "daemon";
      serviceConfig = {
        ProgramArguments = [
          "/bin/sh" "-c"
          "/bin/wait4path ${config.nix.package} &amp;&amp; exec ${config.nix.package}/bin/nix-store --optimise"
        ];
        RunAtLoad = false;
        StartCalendarInterval = [ cfg.interval ];
        UserName = cfg.user;
      };
    };

  };
}
