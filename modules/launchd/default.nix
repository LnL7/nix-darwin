{ config, lib, pkgs, ... }:

with import ./lib.nix { inherit lib; };
with lib;

let

  cfg = config.launchd;

  launchdConfig = import ./launchd.nix;

  serviceOptions =
    { config, name, ... }:
    { options = {
        plist = mkOption {
          internal = true;
          type = types.path;
          description = "The generated plist.";
        };

        serviceConfig = mkOption {
          type = types.submodule launchdConfig;
          example =
            { Program = "/run/current-system/sw/bin/nix-daemon";
              KeepAlive = true;
            };
          default = {};
          description = ''
            Each attribute in this set specifies an option for a <key> in the plist.
            https://developer.apple.com/legacy/library/documentation/Darwin/Reference/ManPages/man5/launchd.plist.5.html
          '';
        };
      };

      config = {
        serviceConfig.Label = mkDefault "org.nixos.${name}";

        plist = pkgs.writeText "${config.serviceConfig.Label}.plist" (toPLIST config.serviceConfig);
      };
    };

in {
  options = {

    launchd.agents = mkOption {
      default = {};
      type = types.attrsOf (types.submodule serviceOptions);
      description = "Definition of launchd agents.";
    };

    launchd.daemons = mkOption {
      default = {};
      type = types.attrsOf (types.submodule serviceOptions);
      description = "Definition of launchd daemons.";
    };

    launchd.user.agents = mkOption {
      default = {};
      type = types.attrsOf (types.submodule serviceOptions);
      description = "Definition of launchd per-user agents.";
    };

  };

  config = {

    system.build.launchd = pkgs.stdenvNoCC.mkDerivation {
      name = "launchd-library";
      preferLocalBuild = true;

      buildCommand = ''
        mkdir -p $out/Library/LaunchDaemons
        ln -s ${cfg.daemons.nix-daemon.plist} $out/Library/LaunchDaemons/${cfg.daemons.nix-daemon.serviceConfig.Label}.plist
      '';
    };

    system.activationScripts.launchd.text = ''
      # Set up launchd services in /Library/LaunchAgents, /Library/LaunchDaemons and ~/Library/LaunchAgents
      echo "setting up launchd services..."

      launchctl unload '/Library/LaunchDaemons/${cfg.daemons.nix-daemon.serviceConfig.Label}.plist'
      ln -sfn '${cfg.daemons.nix-daemon.plist}' '/Library/LaunchDaemons/${cfg.daemons.nix-daemon.serviceConfig.Label}.plist'
      launchctl load '/Library/LaunchDaemons/${cfg.daemons.nix-daemon.serviceConfig.Label}.plist'

    '';

  };
}
