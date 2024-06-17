{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.ollama;

in {
  options = {
    services.ollama = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the Ollama Daemon.";
      };

      package = mkOption {
        type = types.path;
        default = pkgs.ollama;
        description = "This option specifies the ollama package to use.";
      };

      host = mkOption {
        type = types.str;
        default = "127.0.0.1";
        example = "0.0.0.0";
        description = ''
          The host address which the ollama server HTTP interface listens to.
        '';
      };

      port = mkOption {
        type = types.port;
        default = 11434;
        example = 11111;
        description = ''
          Which port the ollama server listens to.
        '';
      };

      home = lib.mkOption {
        type = types.str;
        default = "$HOME";
        example = "/home/foo";
        description = ''
          The home directory that the ollama service is started in.
        '';
      };

      models = mkOption {
        type = types.str;
        default = "$HOME/.ollama/models";
        example = "/path/to/ollama/models";
        description = ''
          The directory that the ollama service will read models from and download new models to.
        '';
      };

      environmentVariables = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = {
          OLLAMA_LLM_LIBRARY = "cpu";
          HIP_VISIBLE_DEVICES = "0,1";
        };
        description = ''
          Set arbitrary environment variables for the ollama service.

          Be aware that these are only seen by the ollama server (launchd daemon),
          not normal invocations like `ollama run`.
          Since `ollama run` is mostly a shell around the ollama server, this is usually sufficient.
        '';
      };

      logFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/var/tmp/ollama.log";
        description = ''
          The file to write the ollama server logs to.
          If not set, logs are written to stdout.
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    environment.systemPackages = [ cfg.package ];

    launchd.user.agents.ollama = {
      path = [ config.environment.systemPath ];

      serviceConfig = {
        KeepAlive = true;
        RunAtLoad = true;
        ProgramArguments = [ "${cfg.package}/bin/ollama" "serve" ];

        StandardOutPath = cfg.logFile;
        StandardErrorPath = cfg.logFile;

        EnvironmentVariables = cfg.environmentVariables // {
          HOME = cfg.home;
          OLLAMA_MODELS = cfg.models;
          OLLAMA_HOST = "${cfg.host}:${toString cfg.port}";
        };
      };
    };
  };
}
