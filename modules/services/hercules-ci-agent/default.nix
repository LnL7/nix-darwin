{ config, lib, pkgs, ... }:

with lib;
let
  cfg = config.services.hercules-ci-agent;
  user = config.users.users._hercules-ci-agent;
in
{
  imports = [ ./common.nix ];

  meta.maintainers = [
    lib.maintainers.roberth or "roberth"
  ];

  options.services.hercules-ci-agent = {

    logFile = mkOption {
      type = types.path;
      default = "/var/log/hercules-ci-agent.log";
      description = "Stdout and sterr of hercules-ci-agent process.";
    };
  };

  config = mkIf cfg.enable {
    launchd.daemons.hercules-ci-agent = {
      script = "exec ${cfg.package}/bin/hercules-ci-agent --config ${cfg.tomlFile}";

      path = [ config.nix.package ];
      environment = {
        NIX_SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      };

      serviceConfig.KeepAlive = true;
      serviceConfig.RunAtLoad = true;
      serviceConfig.StandardErrorPath = cfg.logFile;
      serviceConfig.StandardOutPath = cfg.logFile;
      serviceConfig.GroupName = "_hercules-ci-agent";
      serviceConfig.UserName = "_hercules-ci-agent";
      serviceConfig.WorkingDirectory = user.home;
      serviceConfig.WatchPaths = [
        cfg.settings.staticSecretsDirectory
      ];
    };

    system.activationScripts.preActivation.text = ''
      touch '${cfg.logFile}'
      chown ${toString user.uid}:${toString user.gid} '${cfg.logFile}'
    '';

    # Trusted user allows simplified configuration and better performance
    # when operating in a cluster.
    nix.trustedUsers = [ "_hercules-ci-agent" ];
    services.hercules-ci-agent.settings.nixUserIsTrusted = true;

    users.knownGroups = [ "hercules-ci-agent" "_hercules-ci-agent" ];
    users.knownUsers = [ "hercules-ci-agent" "_hercules-ci-agent" ];

    users.users._hercules-ci-agent = {
      uid = mkDefault 399;
      gid = mkDefault config.users.groups._hercules-ci-agent.gid;
      home = mkDefault cfg.settings.baseDirectory;
      name = "_hercules-ci-agent";
      createHome = true;
      shell = "/bin/bash";
      description = "System user for the Hercules CI Agent";
    };
    users.groups._hercules-ci-agent = {
      gid = mkDefault 399;
      name = "_hercules-ci-agent";
      description = "System group for the Hercules CI Agent";
    };
  };
}
