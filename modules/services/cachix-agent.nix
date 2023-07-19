{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.cachix-agent;
in {
  options.services.cachix-agent = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc ''
        Enable to run Cachix Agent as a system service.
        
        Read [Cachix Deploy](https://docs.cachix.org/deploy/) documentation for more information.
      '';
    };

    name = mkOption {
      type = types.str;
      default = config.networking.hostName;
      description = lib.mdDoc ''
        Agent name, usually the same as the hostname.
      '';
    };

    package = mkOption {
      description = lib.mdDoc ''
        Package containing cachix executable.
      '';
      type = types.package;
      default = pkgs.cachix;
      defaultText = literalExpression "pkgs.cachix";
    };

    credentialsFile = mkOption {
      type = types.path;
      default = "/etc/cachix-agent.token";
      description = lib.mdDoc ''
        Required file that needs to contain:
       
          export CACHIX_AGENT_TOKEN=...
      '';
    };

    logFile = mkOption {
      type = types.nullOr types.path;
      default = "/var/log/cachix-agent.log";
      description = lib.mdDoc "Absolute path to log all stderr and stdout";
    };
  };

  config = mkIf cfg.enable {
    launchd.daemons.cachix-agent = {
      script = ''
        . ${cfg.credentialsFile}

        exec ${cfg.package}/bin/cachix deploy agent ${cfg.name}
      '';

      path = [ config.nix.package pkgs.coreutils ];

      environment = {
        NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
        USER = "root";
      };

      serviceConfig.KeepAlive = true;
      serviceConfig.RunAtLoad = true;
      serviceConfig.ProcessType = "Interactive";
      serviceConfig.StandardErrorPath = cfg.logFile;
      serviceConfig.StandardOutPath = cfg.logFile;
      serviceConfig.WatchPaths = [
        cfg.credentialsFile
      ];
    };
  };
}
