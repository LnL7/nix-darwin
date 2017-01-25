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
    let

      cmd = config.command;
      env = config.environment // optionalAttrs (config.path != "") { PATH = config.path; };

    in

    { options = {
        environment = mkOption {
          type = types.attrsOf (types.either types.str (types.listOf types.str));
          default = {};
          example = { PATH = "/foo/bar/bin"; LANG = "nl_NL.UTF-8"; };
          description = "Environment variables passed to the service's processes.";
          apply = mapAttrs (n: v: if isList v then concatStringsSep ":" v else v);
        };

        path = mkOption {
          type = types.listOf types.path;
          default = [];
          apply = ps: "${makeBinPath ps}";
          description = ''
            Packages added to the service's <envar>PATH</envar>
            environment variable.  Both the <filename>bin</filename>
            and <filename>sbin</filename> subdirectories of each
            package are added.
          '';
        };

        command = mkOption {
          type = types.either types.str types.path;
          default = "";
          description = "Command executed as the service's main process.";
        };

        # preStart = mkOption {
        #   type = types.lines;
        #   default = "";
        #   description = ''
        #     Shell commands executed before the service's main process
        #     is started.
        #   '';
        # };

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
        serviceConfig.ProgramArguments = mkIf (cmd != "") [ "/bin/sh" "-c" "exec ${cmd}" ];
        serviceConfig.EnvironmentVariables = mkIf (env != {}) env;
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
