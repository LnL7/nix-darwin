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

      exec = mkOption {
        type = types.str;
        default = "emacs";
        description = "Emacs command/binary to execute.";
      };
    };
  };

  config = mkIf cfg.enable {

    launchd.user.agents.emacs = {
      serviceConfig.ProgramArguments = [
        "${cfg.package}/bin/${cfg.exec}"
        "--daemon"
      ];
      serviceConfig.RunAtLoad = true;
    };

  };
}
