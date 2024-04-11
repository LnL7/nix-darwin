{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.skhd;
in

{
  options = {
    services.skhd.enable = mkOption {
      type = types.bool;
      default = false;
      description = lib.mdDoc "Whether to enable the skhd hotkey daemon.";
    };

    services.skhd.package = mkOption {
      type = types.package;
      default = pkgs.skhd;
      description = lib.mdDoc "This option specifies the skhd package to use.";
    };

    services.skhd.skhdConfig = mkOption {
      type = types.lines;
      default = "";
      example = "alt + shift - r   :   chunkc quit";
      description = lib.mdDoc "Config to use for {file}`skhdrc`.";
    };
  };

  config = mkIf cfg.enable {

    environment.etc."skhdrc".text = cfg.skhdConfig;

    # Hot-reload workaround until https://github.com/koekeishiya/skhd/issues/342 is fixed
    system.activationScripts.postActivation.text = ''
      su - $(${pkgs.coreutils}/bin/logname) -c '${cfg.package}/bin/skhd -r'
    '';

    launchd.user.agents.skhd = {
      path = [ config.environment.systemPath ];

      serviceConfig.ProgramArguments = [ "${cfg.package}/bin/skhd" ]
        ++ optionals (cfg.skhdConfig != "") [ "-c" "/etc/skhdrc" ];
      serviceConfig.KeepAlive = true;
      serviceConfig.ProcessType = "Interactive";
    };

  };
}
