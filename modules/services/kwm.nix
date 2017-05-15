{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.kwm;

in

{
  options = {
    services.kwm.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the khd window manager.";
    };

    services.kwm.package = mkOption {
      type = types.path;
      example = literalExample pkgs.kwm;
      description = "This option specifies the kwm package to use";
    };

    services.kwm.enableAccessibilityAccess = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable accessibility permissions for the kwm daemon.";
    };
  };

  config = mkIf cfg.enable {

    services.kwm.package = mkDefault pkgs.kwm;

    security.accessibilityPrograms = mkIf cfg.enableAccessibilityAccess [ "${cfg.package}/kwm" ];

    launchd.user.agents.kwm = {
      serviceConfig.Program = "${cfg.package}/kwm";
      serviceConfig.KeepAlive = true;
      serviceConfig.ProcessType = "Interactive";
      serviceConfig.Sockets.Listeners =
        { SockServiceName = "3020";
          SockType = "dgram";
          SockFamily = "IPv4";
        };
    };

  };
}
