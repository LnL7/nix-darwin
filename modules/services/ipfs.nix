{ config, lib, pkgs, ... }:

with lib;

let cfg = config.services.ipfs;
in {
  options = {
    services.ipfs = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "Whether to enable the ipfs service.";
      };

      logFile = mkOption {
        type = types.nullOr types.path;
        default = null;
        example = "/var/tmp/ipfs.log";
        description = ''
          The logfile to use for the ipfs service. Alternatively
          <command>sudo launchctl debug system/org.nixos.ipfs --stderr</command>
          can be used to stream the logs to a shell after restarting the service with
          <command>sudo launchctl kickstart -k system/org.nixos.ipfs</command>.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.ipfs ];
    launchd.user.agents.ipfs = {
      command = with pkgs; "${ipfs}/bin/ipfs daemon --init";
      path = with pkgs; [ config.nix.package git gnutar gzip ];
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
