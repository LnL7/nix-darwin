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
      default = pkgs.kwm;
      defaultText = "pkgs.kwm";
      description = "This option specifies the kwm package to use";
    };

    services.kwm.enableAccessibilityAccess = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable accessibility permissions for the kwm daemon.";
    };

    services.kwm.kwmConfig = mkOption {
      type = types.lines;
      default = "";
      example = ''kwmc rule owner="iTerm2" properties={role="AXDialog"}'';
    };
  };

  config = mkIf cfg.enable {

    security.accessibilityPrograms = mkIf cfg.enableAccessibilityAccess [ "${cfg.package}/kwm" ];

    environment.etc."kwmrc".text = cfg.kwmConfig;

    launchd.user.agents.kwm = {
      serviceConfig.ProgramArguments = [ "${cfg.package}/kwm" ]
        ++ optionals (cfg.kwmConfig != "") [ "-c" "/etc/kwmrc" ];
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
