{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.khd;

in

{
  options = {
    services.khd.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the khd hototkey daemon.";
    };

    services.khd.package = mkOption {
      type = types.package;
      example = literalExample "pkgs.khd";
      description = "This option specifies the khd package to use.";
    };
  };

  config = mkIf cfg.enable {

    services.khd.package = mkDefault pkgs.khd;

    launchd.user.agents.khd = {
      path = [ cfg.package pkgs.kwm config.environment.systemPath ];
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
