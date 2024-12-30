{
  config,
  lib,
  pkgs,
  ...
}:
let

  dataDir = "/var/lib/consul";
  cfg = config.services.consul;

  configOptions = {
    data_dir = dataDir;
    ui_config = {
      enabled = cfg.webUi;
    };
  } // cfg.extraConfig;

  configFiles = [
    "/etc/consul.json"
  ] ++ cfg.extraConfigFiles;
in
{
  meta.maintainers = [ lib.maintainers.mjm or "mjm" ];

  options = {
    services.consul = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Enables the consul daemon.
        '';
      };

      package = lib.mkPackageOption pkgs "consul" { };

      webUi = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Enables the web interface on the consul http port.
        '';
      };

      extraConfig = lib.mkOption {
        default = { };
        type = lib.types.attrsOf lib.types.anything;
        description = ''
          Extra configuration options which are serialized to json and added
          to the config.json file.
        '';
      };

      extraConfigFiles = lib.mkOption {
        default = [ ];
        type = lib.types.listOf lib.types.str;
        description = ''
          Additional configuration files to pass to consul
          NOTE: These will not trigger the service to be restarted when altered.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.consul = {
      uid = config.ids.uids.consul;
      gid = config.ids.gids.consul;
      description = "Consul agent daemon user";
      home = dataDir;
      createHome = true;
      # The shell is needed for health checks
      shell = "/run/current-system/sw/bin/bash";
    };
    users.groups.consul = {
      gid = config.ids.gids.consul;
    };
    users.knownUsers = [ "consul" ];
    users.knownGroups = [ "consul" ];

    environment = {
      etc."consul.json".text = builtins.toJSON configOptions;
      # We need consul.d to exist for consul to start
      etc."consul.d/dummy.json".text = "{ }";
      systemPackages = [ cfg.package ];
    };

    launchd.daemons.consul = {
      path = [ cfg.package ];
      script = lib.concatStringsSep " " (
        [
          "consul"
          "agent"
          "-config-dir"
          "/etc/consul.d"
        ]
        ++ lib.concatMap (n: [
          "-config-file"
          n
        ]) configFiles
      );
      serviceConfig =
        let
          logPath = "${dataDir}/consul.log";
        in
        {
          KeepAlive = true;
          RunAtLoad = true;
          StandardErrorPath = logPath;
          StandardOutPath = logPath;
          GroupName = "consul";
          UserName = "consul";
        };
    };
  };
}
