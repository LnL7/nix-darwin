{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.postgresql;

  configFile = pkgs.writeText "postgresql.conf"
    ''
      log_destination = 'stderr'
      port = ${toString cfg.port}
      ${cfg.extraConfig}
    '';
in

{
  options = {
    services.postgresql = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''Whether to run PostgreSQL.'';
      };

      package = mkOption {
        type = types.package;
        default = pkgs.postgresql96;
        defaultText = "pkgs.postgresql96";
        description = ''PostgreSQL package to use.'';
      };

      port = mkOption {
        type = types.int;
        default = 5432;
        description = ''The port on which PostgreSQL listens.'';
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/postgresql";
        example = "/var/lib/postgresql/9.6";
        description = ''Data directory for PostgreSQL.'';
      };

      enableTCPIP = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether PostgreSQL should listen on all network interfaces.
          If disabled, the database can only be accessed via its Unix
          domain socket or via TCP connections to localhost.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = "Additional text to be appended to <filename>postgresql.conf</filename>.";
      };
    };
  };

  config = mkIf cfg.enable {

    environment.systemPackages = [ cfg.package ];

    launchd.user.agents.postgresql =
      { path = [ cfg.package ];
        script = ''
          # Initialise the database.
          if ! test -e ${cfg.dataDir}/PG_VERSION; then
            initdb -U postgres -D ${cfg.dataDir}
          fi
          ${pkgs.coreutils}/bin/ln -sfn ${configFile} ${cfg.dataDir}/postgresql.conf

          exec ${cfg.package}/bin/postgres -D ${cfg.dataDir} ${optionalString cfg.enableTCPIP "-i"}
        '';

        serviceConfig.KeepAlive = true;
        serviceConfig.RunAtLoad = true;
      };

  };
}
