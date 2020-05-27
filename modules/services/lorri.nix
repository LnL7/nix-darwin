{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.lorri;

in {

  options = {
    services.lorri = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable to Lorri Daemon.";
      };

      package = mkOption {
        type = types.path;
        default = pkgs.lorri;
        description = "This option specifies the lorri package to use.";
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    launchd.user.agents.lorri = {
      command = "${cfg.package}/bin/lorri daemon";
      serviceConfig.KeepAlive = true;
    };

  };
}
