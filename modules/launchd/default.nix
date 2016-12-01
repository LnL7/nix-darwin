{ config, lib, pkgs, ... }:

with import ./lib.nix { inherit lib; };
with lib;

let

  cfg = config.launchd;

  toEnvironmentText = name: value: {
    name = "${value.serviceConfig.Label}.plist";
    value.text = toPLIST value.serviceConfig;
  };

  launchdConfig = import ./launchd.nix;

  serviceOptions =
    { config, name, ... }:
    { options = {
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
      };
    };

in

{
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

  };

  config = {

    environment.launchAgents = mapAttrs' toEnvironmentText cfg.agents;
    environment.launchDaemons = mapAttrs' toEnvironmentText cfg.daemons;

  };
}
