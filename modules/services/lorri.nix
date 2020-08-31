{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.lorri;
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
        default = null;
        example =  "/var/tmp/lorri.log";
        description = ''
          The logfile to use for the lorri service. Alternatively
          <command>sudo launchctl debug system/org.nixos.lorri --stderr</command>
          can be used to stream the logs to a shell after restarting the service with
          <command>sudo launchctl kickstart -k system/org.nixos.lorri</command>.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.lorri ];
    launchd.user.agents.lorri = {
      command = with pkgs; "${lorri}/bin/lorri daemon";
      path = with pkgs; [ nix ];
      serviceConfig = {
        KeepAlive = true;
        RunAtLoad = true;
        ProcessType = "Background";
        StandardOutPath = cfg.logFile;
        StandardErrorPath = cfg.logFile;
        EnvironmentVariables = { NIX_PATH = "nixpkgs=" + toString pkgs.path; };
      };
    };
  };
}