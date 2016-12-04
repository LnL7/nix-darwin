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

      profile = mkOption {
        type = types.path;
        default = "/nix/var/nix/profiles/default";
        description = "Profile to use for nix and cacert.";
      };

      buildMachinesFile = mkOption {
        type = types.path;
        default = "/etc/nix/machines";
        description = "File containing build machines.";
      };

      tempDir = mkOption {
        type = types.path;
        default = "/tmp";
        description = "The TMPDIR to use for nix-daemon.";
      };

    };
  };

  config = {

    launchd.daemons.nix-daemon = mkIf cfg.enable {
      serviceConfig.Program = "${cfg.profile}/bin/nix-daemon";
      serviceConfig.KeepAlive = true;
      serviceConfig.ProcessType = "Background";
      serviceConfig.SoftResourceLimits.NumberOfFiles = 4096;
      serviceConfig.EnvironmentVariables.TMPDIR = "${cfg.tempDir}";
      serviceConfig.EnvironmentVariables.SSL_CERT_FILE = "${cfg.profile}/etc/ssl/certs/ca-bundle.crt";
      serviceConfig.EnvironmentVariables.NIX_BUILD_HOOK="${cfg.profile}/libexec/nix/build-remote.pl";
      serviceConfig.EnvironmentVariables.NIX_CURRENT_LOAD="${cfg.tempDir}/current-load";
      serviceConfig.EnvironmentVariables.NIX_REMOTE_SYSTEMS="${cfg.buildMachinesFile}";
    };

  };
}
