{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.nextdns;
  nextdns = pkgs.nextdns;

in {
  options = {
    services.nextdns = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description =
          lib.mdDoc "Whether to enable the NextDNS DNS/53 to DoH Proxy service.";
      };
      arguments = mkOption {
        type = types.listOf types.str;
        default = [ ];
        example = [ "-config" "10.0.3.0/24=abcdef" ];
        description = lib.mdDoc "Additional arguments to be passed to nextdns run.";
      };
    };
  };

  config = mkIf cfg.enable {

    environment.systemPackages = [ nextdns ];

    launchd.daemons.nextdns = {
      path = [ nextdns ];
      serviceConfig.ProgramArguments =
        [ "${pkgs.nextdns}/bin/nextdns" "run" (escapeShellArgs cfg.arguments) ];
      serviceConfig.KeepAlive = true;
      serviceConfig.RunAtLoad = true;
    };

  };
}
