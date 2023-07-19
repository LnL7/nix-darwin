{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.synapse-bt;
  configOptions = recursiveUpdate {
    port = cfg.port;
    disk = {
      directory = cfg.downloadDir;
    };
  } cfg.extraConfig;

  configFile = pkgs.runCommand "config.toml" {
    buildInputs = [ pkgs.remarshal ];
  } ''
    remarshal -if json -of toml \
      < ${pkgs.writeText "config.json" (builtins.toJSON configOptions)} \
      > $out
  '';
in

{
  options = {
    services.synapse-bt = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc "Whether to run Synapse BitTorrent Daemon.";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.synapse-bt;
        defaultText = "pkgs.synapse-bt";
        description = lib.mdDoc "Synapse BitTorrent package to use.";
      };

      port = mkOption {
        type = types.int;
        default = 16384;
        description = lib.mdDoc "The port on which Synapse BitTorrent listens.";
      };

      downloadDir = mkOption {
        type = types.path;
        default = "/var/lib/synapse-bt";
        example = "/var/lib/synapse-bt/downloads";
        description = lib.mdDoc "Download directory for Synapse BitTorrent.";
      };

      extraConfig = mkOption {
        default = {};
        description = lib.mdDoc "Extra configuration options for Synapse BitTorrent.";
        type = types.attrs;
      };
    };
  };

  config = mkIf cfg.enable {

    environment.systemPackages = [ cfg.package ];

    launchd.user.agents.synapse-bt =
      { path = [ cfg.package ];
        command = "${cfg.package}/bin/synapse --config ${configFile}";
        serviceConfig.KeepAlive = true;
        serviceConfig.RunAtLoad = true;
      };

  };
}
