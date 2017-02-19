{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.emacs;

in

{
  options = {
    services.emacs = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the Emacs Daemon.";
      };

      package = mkOption {
        type = types.path;
        default = pkgs.emacs;
        description = "This option specifies the emacs package to use.";
      };

    };
  };

  config = mkIf cfg.enable {

    launchd.user.agents.emacs = {
      serviceConfig.ProgramArguments = [
        "${cfg.package}/bin/emacs"
        "--daemon"
      ];
      serviceConfig.RunAtLoad = true;
    };

  };
}