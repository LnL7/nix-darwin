{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.lorri;
in
{
  options = {
    services.lorri.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the lorri service.";
    };

    services.lorri.package = mkOption {
      type = types.path;
      default = pkgs.lorri;
      defaultText = "pkgs.lorri";
      description = "This option specifies the lorri package to use.";
    };

    services.lorri.logFile = mkOption {
      type = types.nullOr types.path;
      default = "/var/tmp/lorri.log";
      example =  "/var/tmp/lorri.log";
      description = ''
        The logfile to use for the lorri service. Alternatively
        <command>sudo launchctl debug system/org.nixos.lorri --stderr</command>
        can be used to stream the logs to a shell after restarting the service with
        <command>sudo launchctl kickstart -k system/org.nixos.lorri</command>.
      '';
    };

    services.lorri.tempDir = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "The TMPDIR to use for lorri.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    launchd.user.agents.lorri = {
      serviceConfig = {
        KeepAlive = true;
        ProcessType = "Background";
        LowPriorityIO = false;
        StandardOutPath = cfg.logFile;
        StandardErrorPath = cfg.logFile;
        EnvironmentVariables = mkMerge [
        config.nix.envVars
        { TMPDIR = mkIf (cfg.tempDir != null) cfg.tempDir; }
        ];
      };
      command = "${cfg.package}/bin/lorri daemon";
    };
  };
}