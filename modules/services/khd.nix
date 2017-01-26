{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.khd;

in

{
  options = {
    services.khd = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the khd hototkey daemon.";
      };

      package = mkOption {
        type = types.path;
        default = pkgs.khd;
        description = "This option specifies the khd package to use";
      };

    };
  };

  config = mkIf cfg.enable {

    launchd.user.agents.khd = {
      path = [ cfg.package pkgs.kwm ];
      serviceConfig.Program = "${cfg.package}/bin/khd";
      serviceConfig.KeepAlive = true;
      serviceConfig.ProcessType = "Interactive";
      serviceConfig.Sockets.Listeners =
        { SockServiceName = "3021";
          SockType = "dgram";
          SockFamily = "IPv4";
        };
    };

  };
}
