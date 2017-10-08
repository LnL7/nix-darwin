{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.networking;

  hostName = optionalString (cfg.hostName != null) ''
    scutil --set ComputerName "${cfg.hostName}"
    scutil --set LocalHostName "${cfg.hostName}"
    scutil --set HostName "${cfg.hostName}"
    defaults write /Library/Preferences/SystemConfiguration/com.apple.smb.server NetBIOSName -string "${cfg.hostName}"
  '';

in

{
  options = {

    networking.hostName = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "myhostname";
      description = ''
        Hostname for your machine.
      '';
    };

  };

  config = {

    system.activationScripts.networking.text = ''
      # Set defaults
      echo "configuring networking..." >&2

      ${hostName}
    '';

  };
}
