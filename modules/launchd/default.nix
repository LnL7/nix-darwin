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
      description = ''
        Definition of per-user launchd agents.

        When a user logs in, a per-user launchd is started.
        It does the following:
        1. It loads the parameters for each launch-on-demand user agent from the property list files found in /System/Library/LaunchAgents, /Library/LaunchAgents, and the user’s individual Library/LaunchAgents directory.
        2. It registers the sockets and file descriptors requested by those user agents.
        3. It launches any user agents that requested to be running all the time.
        4. As requests for a particular service arrive, it launches the corresponding user agent and passes the request to it.
        5. When the user logs out, it sends a SIGTERM signal to all of the user agents that it started.
      '';
    };

    launchd.daemons = mkOption {
      default = {};
      type = types.attrsOf (types.submodule serviceOptions);
      description = ''
        Definition of launchd daemons.

        After the system is booted and the kernel is running, launchd is run to finish the system initialization.
        As part of that initialization, it goes through the following steps:
        1. It loads the parameters for each launch-on-demand system-level daemon from the property list files found in /System/Library/LaunchDaemons/ and /Library/LaunchDaemons/.
        2. It registers the sockets and file descriptors requested by those daemons.
        3. It launches any daemons that requested to be running all the time.
        4. As requests for a particular service arrive, it launches the corresponding daemon and passes the request to it.
        5. When the system shuts down, it sends a SIGTERM signal to all of the daemons that it started.
      '';
    };

  };

  config = {

    environment.launchAgents = mapAttrs' toEnvironmentText cfg.agents;
    environment.launchDaemons = mapAttrs' toEnvironmentText cfg.daemons;

  };
}
