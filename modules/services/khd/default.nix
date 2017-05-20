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
      default = pkgs.khd;
      defaultText = "pkgs.khd";
      description = "This option specifies the khd package to use.";
    };

    services.khd.enableAccessibilityAccess = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable accessibility permissions for the khd daemon.";
    };

    services.khd.khdConfig = mkOption {
      type = types.lines;
      default = "";
      example = "alt + shift - r   : kwmc quit";
    };
  };

  config = mkIf cfg.enable {

    security.accessibilityPrograms = mkIf cfg.enableAccessibilityAccess [ "${cfg.package}/bin/khd" ];

    environment.etc."khdrc".text = cfg.khdConfig;

    launchd.user.agents.khd = {
      path = [ cfg.package pkgs.kwm config.environment.systemPath ];

      serviceConfig.ProgramArguments = [ "${cfg.package}/bin/khd" "-c" "/etc/khdrc" ];
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
