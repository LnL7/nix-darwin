{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.lorri;
  home = "${builtins.getEnv "HOME"}";
in
{
  options =  {
    services.lorri = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the lorri service.";
      };

      logFile = mkOption {
        type = types.nullOr types.path;
        default = "${home}/Library/Logs/lorri.log";
        example =  "${home}/Library/Logs/lorri.log";
        description = ''
          The logfile to use for the lorri service. Alternatively
          <command>sudo launchctl debug system/com.target.lorri --stderr</command>
          can be used to stream the logs to a shell after restarting the service with
          <command>sudo launchctl kickstart -k system/com.target.lorri</command>.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.lorri ];
    launchd.user.agents.lorri = {
      serviceConfig = {
        Label = "com.target.lorri";
        ProgramArguments = with pkgs; ["${zsh}/bin/zsh" "-c" "${lorri}/bin/lorri daemon"];
        KeepAlive = true;
        RunAtLoad = true;
        ProcessType = "Background";
        StandardOutPath = cfg.logFile;
        StandardErrorPath = cfg.logFile;
      };
    };
  };
}