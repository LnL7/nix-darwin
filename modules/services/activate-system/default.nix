{ config, lib, pkgs, ... }:

with lib;

let
  inherit (pkgs) stdenv;

  cfg = config.services.activate-system;
in

{
  options = {
    services.activate-system.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to activate system at boot time.";
    };
  };

  config = mkIf cfg.enable {

    launchd.daemons.activate-system = {
      script = config.system.activationScripts.startupScript;
      serviceConfig.RunAtLoad = true;
      serviceConfig.KeepAlive.SuccessfulExit = false;
    };

  };
}
