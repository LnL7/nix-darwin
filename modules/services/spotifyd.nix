{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.spotifyd;

  format = pkgs.formats.toml { };
  configFile = format.generate "spotifyd.conf" {
    global = {
      backend = "portaudio";
    };
    spotifyd = cfg.settings;
  };
in
{
  options = {
    services.spotifyd = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = lib.mdDoc ''
          Whether to enable the spotifyd service.
        '';
      };

      package = mkOption {
        type = types.path;
        default = pkgs.spotifyd;
        defaultText = "pkgs.spotifyd";
        description = lib.mdDoc ''
          The spotifyd package to use.
        '';
      };

      settings = mkOption {
        type = types.nullOr format.type;
        default = null;
        example = {
          bitrate = 160;
          volume_normalisation = true;
        };
        description = lib.mdDoc ''
          Configuration for spotifyd, see <https://spotifyd.github.io/spotifyd/config/File.html>
          for supported values.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    launchd.user.agents.spotifyd = {
      serviceConfig.ProgramArguments = [ "${cfg.package}/bin/spotifyd" "--no-daemon" ]
        ++ optionals (cfg.settings != null) [ "--config-path=${configFile}" ];
      serviceConfig = {
        KeepAlive = true;
        RunAtLoad = true;
        ThrottleInterval = 30;
      };
    };
  };
}
