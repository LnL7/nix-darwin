{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.mongodb;

  mongodb = cfg.package;

  mongoCnf = cfg:
    pkgs.writeText "mongodb.conf" ''
      net.bindIp: ${cfg.bind_ip}
      ${optionalString cfg.quiet "systemLog.quiet: true"}
      systemLog.destination: syslog
      ${optionalString (cfg.replSetName != "")
      "replication.replSetName: ${cfg.replSetName}"}
      ${cfg.extraConfig}
    '';
  # ${optionalString cfg.enableAuth "security.authorization: enabled"}
in {
  meta.maintainers = [ lib.maintainers.obinmatt or "obinmatt" ];

  ###### interface

  options = {
    services.mongodb = {
      enable = mkEnableOption "the MongoDB server";

      package = mkPackageOption pkgs "mongodb" { };

      user = mkOption {
        type = types.str;
        default = "";
        description = "User account under which MongoDB runs";
      };

      bind_ip = mkOption {
        type = types.str;
        default = "127.0.0.1";
        description = "IP to bind to";
      };

      quiet = mkOption {
        type = types.bool;
        default = false;
        description = "quieter output";
      };

      enableAuth = mkOption {
        type = types.bool;
        default = false;
        description =
          "Enable client authentication. Creates a default superuser with username root!";
      };

      initialRootPassword = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Password for the root user if auth is enabled.";
      };

      dbpath = mkOption {
        type = types.str;
        default = "~/.mongodb/data";
        description = "Location where MongoDB stores its files";
      };

      pidFile = mkOption {
        type = types.str;
        default = "";
        description = "Location of MongoDB pid file";
      };

      replSetName = mkOption {
        type = types.str;
        default = "";
        description = ''
          If this instance is part of a replica set, set its name here.
          Otherwise, leave empty to run as single node.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        example = ''
          storage.journal.enabled: false
        '';
        description = "MongoDB extra configuration in YAML format";
      };

      initialScript = mkOption {
        type = types.nullOr types.path;
        default = null;
        description = ''
          A file containing MongoDB statements to execute on first startup.
        '';
      };
    };
  };

  ###### implementation

  config = mkIf config.services.mongodb.enable {
    # these require a different implementation (user) or functionality that launchd does not provide
    warnings = if cfg.user != "" || cfg.pidFile != "" || cfg.enableAuth != false
    || cfg.initialRootPassword != null || cfg.initialScript != null then
      [
        "Currently nix-darwin does not support mongodb user, enableAuth, initialRootPassword, pidFile or initialScript"
      ]
    else
      [ ];

    environment.systemPackages = [ mongodb ];

    launchd.user.agents.mongodb = {
      path = [ mongodb ];
      serviceConfig = {
        KeepAlive = true;
        RunAtLoad = true;
      };
      script = ''
        # preStart
        rm ${cfg.dbpath}/mongod.lock || true
        if ! test -e ${cfg.dbpath}; then
          ${pkgs.coreutils}/bin/install -d -m 700 ${cfg.dbpath}
        fi

        # start
        exec ${mongodb}/bin/mongod --config ${
          mongoCnf cfg
        } --dbpath ${cfg.dbpath} --fork

        # postStart
        # launchd does not have this functionality
      '';
    };
  };
}
