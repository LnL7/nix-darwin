{ config, lib, pkgs, ... }:
with lib;

let
  cfg = config.services.mopidy;
  mopidyConf = pkgs.writeText "mopidy.conf" cfg.configuration;
  mopidyEnv = pkgs.buildEnv {
    name = "mopidy-with-extensions-${cfg.package.version}";
    paths = closePropagation cfg.extensionPackages;
    pathsToLink = [ "/${pkgs.mopidyPackages.python.sitePackages}" ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      makeWrapper ${cfg.package}/bin/mopidy $out/bin/mopidy \
        --prefix PYTHONPATH : $out/${pkgs.mopidyPackages.python.sitePackages}
    '';
  };

in
{
  options = {
    services.mopidy.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Whether to enable the Mopidy Daemon.";
    };

    services.mopidy.package = mkOption {
      type = types.path;
      default = pkgs.mopidy;
      defaultText = "pkgs.mopidy";
      description = "This option specifies the mopidy package to use.";
    };

    services.mopidy.extensionPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Mopidy extensions that should be loaded by the service.";
    };

    services.mopidy.configuration = mkOption {
      default = "";
      type = types.lines;
      description = "The configuration that Mopidy should use.";
    };

    services.mopidy.mediakeys.enable = mkOption {
      type = types.bool;
      default = false;
      description =
        "Whether to enable the Mopidy OSX Media Keys support daemon.";
    };

    services.mopidy.mediakeys.package = mkOption {
      type = types.path;
      default = pkgs.pythonPackages.osxmpdkeys;
      defaultText = "pkgs.pythonPackages.osxmpdkeys";
      description = "This option specifies the mediakeys package to use.";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      launchd.user.agents.mopidy = {
        serviceConfig.ProgramArguments =
          [ "${mopidyEnv}/bin/mopidy" "--config" "${mopidyConf}" ];
        serviceConfig.RunAtLoad = true;
        serviceConfig.KeepAlive = true;
      };
    })
    (mkIf cfg.mediakeys.enable {
      launchd.user.agents.mopidymediakeys = {
        serviceConfig.Program = "${cfg.package}/bin/mpdkeys";
        serviceConfig.RunAtLoad = true;
        serviceConfig.KeepAlive = true;
      };
    })
  ];
}
