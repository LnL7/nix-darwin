{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.postgresql;

  postgresqlAndPlugins = pg:
    if cfg.extraPlugins == [] then pg
    else pkgs.buildEnv {
      name = "postgresql-and-plugins-${(builtins.parseDrvName pg.name).version}";
      paths = [ pg pg.lib ] ++ cfg.extraPlugins;
      # We include /bin to ensure the $out/bin directory is created which is
      # needed because we'll be removing files from that directory in postBuild
      # below.
      pathsToLink = [ "/" "/bin" ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        rm $out/bin/{pg_config,postgres,pg_ctl}
        cp --target-directory=$out/bin ${pg}/bin/{postgres,pg_config,pg_ctl}
        wrapProgram $out/bin/postgres --set NIX_PGLIBDIR $out/lib
      '';
    };

  postgresql = postgresqlAndPlugins cfg.package;

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

      characterSet = mkOption {
        type = types.str;
        default = "UTF8";
        example = "SJIS";
        description = ''Character set specified during initialization'';
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

      extraPlugins = mkOption {
        type = types.listOf types.path;
        default = [];
        example = literalExample "[ (pkgs.postgis.override { postgresql = pkgs.postgresql94; }) ]";
        description = ''
          When this list contains elements a new store path is created.
          PostgreSQL and the elements are symlinked into it. Then pg_config,
          postgres and pg_ctl are copied to make them use the new
          $out/lib directory as pkglibdir. This makes it possible to use postgis
          without patching the .sql files which reference $libdir/postgis-1.5.
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

    environment.systemPackages = [ postgresql ];

    launchd.user.agents.postgresql =
      { path = [ postgresql ];
        script = ''
          # Initialise the database.
          if ! test -e ${cfg.dataDir}/PG_VERSION; then
            initdb -U postgres -D ${cfg.dataDir} -E ${cfg.characterSet}
          fi
          ${pkgs.coreutils}/bin/ln -sfn ${configFile} ${cfg.dataDir}/postgresql.conf

          exec ${postgresql}/bin/postgres -D ${cfg.dataDir} ${optionalString cfg.enableTCPIP "-i"}
        '';

        serviceConfig.KeepAlive = true;
        serviceConfig.RunAtLoad = true;
      };

  };
}
