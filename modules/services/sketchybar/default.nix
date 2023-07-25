{ config, lib, pkgs, ... }:

let
  inherit (lib) literalExpression maintainers mdDoc mkEnableOption mkIf mkPackageOptionMD mkOption optionals types;

  cfg = config.services.sketchybar;

  configFile = pkgs.writeScript "sketchybarrc" cfg.config;
in

{

  meta.maintainers = [
    maintainers.azuwis or "azuwis"
  ];

  options.services.sketchybar = {
    enable = mkEnableOption (mdDoc "sketchybar");

    package = mkPackageOptionMD pkgs "sketchybar" { };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      example = literalExpression "[ pkgs.jq ]";
      description = mdDoc ''
        Extra packages to add to PATH.
      '';
    };

    config = mkOption {
      type = types.lines;
      default = "";
      example = ''
        sketchybar --bar height=24
        sketchybar --update
        echo "sketchybar configuration loaded.."
      '';
      description = mdDoc ''
        Contents of sketchybar's configuration file. If empty (the default), the configuration file won't be managed.

        See [documentation](https://felixkratz.github.io/SketchyBar/)
        and [example](https://github.com/FelixKratz/SketchyBar/blob/master/sketchybarrc).
      '';
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    launchd.user.agents.sketchybar = {
      path = [ cfg.package ] ++ cfg.extraPackages ++ [ config.environment.systemPath ];
      serviceConfig.ProgramArguments = [ "${cfg.package}/bin/sketchybar" ]
        ++ optionals (cfg.config != "") [ "--config" "${configFile}" ];
      serviceConfig.KeepAlive = true;
      serviceConfig.RunAtLoad = true;
    };
  };
}
