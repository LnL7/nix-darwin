{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.nix-daemon;

in

{
  options = {
    services.nix-daemon = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to activate system at boot time.";
      };

      tempDir = mkOption {
        type = types.path;
        default = "/tmp";
        description = "The TMPDIR to use for nix-daemon.";
      };

    };
  };

  config = mkIf cfg.enable {

    environment.extraInit = ''
      # Set up secure multi-user builds: non-root users build through the
      # Nix daemon.
      if [ "$USER" != root -o ! -w /nix/var/nix/db ]; then
          export NIX_REMOTE=daemon
      fi
    '';

    launchd.daemons.nix-daemon = {
      command = "${config.nix.package}/bin/nix-daemon";
      serviceConfig.KeepAlive = true;
      serviceConfig.ProcessType = "Interactive";
      serviceConfig.LowPriorityIO = config.nix.daemonIONice;
      serviceConfig.Nice = config.nix.daemonNiceLevel;
      serviceConfig.SoftResourceLimits.NumberOfFiles = 4096;

      serviceConfig.EnvironmentVariables = config.nix.envVars
        # // { CURL_CA_BUNDLE = "/etc/ssl/certs/ca-certificates.crt"; }
        // { SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"; }
        // { TMPDIR = "${cfg.tempDir}"; };
    };

  };
}
