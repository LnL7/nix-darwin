{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.nix-daemon;
in

{
  options = {
    services.nix-daemon.enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "Whether to enable the nix-daemon service.";
    };

    services.nix-daemon.enableSocketListener = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "Whether to make the nix-daemon service socket activated.";
    };

    services.nix-daemon.logFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      example = "/var/log/nix-daemon.log";
      description = lib.mdDoc ''
        The logfile to use for the nix-daemon service. Alternatively
        {command}`sudo launchctl debug system/org.nixos.nix-daemon --stderr`
        can be used to stream the logs to a shell after restarting the service with
        {command}`sudo launchctl kickstart -k system/org.nixos.nix-daemon`.
      '';
    };

    services.nix-daemon.tempDir = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = lib.mdDoc "The TMPDIR to use for nix-daemon.";
    };
  };

  config = mkIf cfg.enable {

    nix.useDaemon = true;

    launchd.daemons.nix-daemon = {
      serviceConfig.ProgramArguments = [
        "/bin/sh" "-c"
        "/bin/wait4path ${config.nix.package}/bin/nix-daemon &amp;&amp; exec ${config.nix.package}/bin/nix-daemon"
      ];
      serviceConfig.ProcessType = config.nix.daemonProcessType;
      serviceConfig.LowPriorityIO = config.nix.daemonIOLowPriority;
      serviceConfig.Label = "org.nixos.nix-daemon"; # must match daemon installed by Nix regardless of the launchd label Prefix
      serviceConfig.SoftResourceLimits.NumberOfFiles = mkDefault 4096;
      serviceConfig.StandardErrorPath = cfg.logFile;

      serviceConfig.KeepAlive = mkIf (!cfg.enableSocketListener) true;

      serviceConfig.Sockets = mkIf cfg.enableSocketListener
        { Listeners.SockType = "stream";
          Listeners.SockPathName = "/nix/var/nix/daemon-socket/socket";
        };

      serviceConfig.EnvironmentVariables = mkMerge [
        config.nix.envVars
        {
          NIX_SSL_CERT_FILE = mkIf
            (config.environment.variables ? NIX_SSL_CERT_FILE)
            (mkDefault config.environment.variables.NIX_SSL_CERT_FILE);
          TMPDIR = mkIf (cfg.tempDir != null) cfg.tempDir;
          # FIXME: workaround for https://github.com/NixOS/nix/issues/2523
          OBJC_DISABLE_INITIALIZE_FORK_SAFETY = mkDefault "YES";
        }
      ];
    };

  };
}
