{ config, lib, pkgs, ... }:

let
  cfg = config.services.telegraf;

  configFile = pkgs.runCommand "config.toml" {
    buildInputs = [ pkgs.remarshal ];
    preferLocalBuild = true;
  } ''
    remarshal -if json -of toml \
      < ${pkgs.writeText "config.json" (builtins.toJSON cfg.extraConfig)} \
      > $out
  '';
in {
  options = {
    services.telegraf = {
      enable = lib.mkEnableOption "telegraf server";

      package = lib.mkOption {
        default = pkgs.telegraf;
        defaultText = "pkgs.telegraf";
        description = "Which telegraf derivation to use";
        type = lib.types.package;
      };

      extraConfig = lib.mkOption {
        default = {};
        description = "Extra configuration options for telegraf";
        type = lib.types.attrs;
        example = {
          outputs.influxdb = [{
            urls = ["http://localhost:8086"];
            database = "telegraf";
          }];
          inputs.statsd = [{
            service_address = ":8125";
            delete_timings = true;
          }];
        };
      };
    };
  };

  config = lib.mkIf config.services.telegraf.enable {
    launchd.daemons.telegraf = {
      script = "${cfg.package}/bin/telegraf -config ${configFile}";

      serviceConfig = {
        Label = "telegraf";
        RunAtLoad = true;
        KeepAlive.NetworkState = true;
      };
    };
  };
}
