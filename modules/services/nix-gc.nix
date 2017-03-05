{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.nix.gc;
in

{
  options = {
    nix.gc = {

      automatic = mkOption {
        default = false;
        type = types.bool;
        description = "Automatically run the garbage collector at a specific time.";
      };

      # TODO: parse dates
      # dates = mkOption {
      #   default = "03:15";
      #   type = types.str;
      #   description = ''
      #     Specification (in the format described by
      #     <citerefentry><refentrytitle>systemd.time</refentrytitle>
      #     <manvolnum>5</manvolnum></citerefentry>) of the time at
      #     which the garbage collector will run.
      #   '';
      # };

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

  config = mkIf cfg.automatic {

    launchd.daemons.nix-gc = {
      command = "${config.nix.package}/bin/nix-collect-garbage ${cfg.options}";
      serviceConfig.RunAtLoad = false;
      serviceConfig.StartCalendarInterval = mkDefault
        [ { Hour = 3; Minute = 15; }
        ];
    };

  };
}
