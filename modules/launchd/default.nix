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
          type = types.path;
          internal = true;
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

        plist = pkgs.writeText "${config.serviceConfig.Label}.plist" ''
          <?xml version="1.0" encoding="UTF-8"?>
          <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
          <plist version="1.0">
            <dict>
              ${xmlMapAttr xmlString "Label" config.serviceConfig.Label}
              ${xmlMapAttr xmlBool "Disabled" config.serviceConfig.Disabled}
              ${xmlMapAttr xmlString "UserName" config.serviceConfig.UserName}
              ${xmlMapAttr xmlString "GroupName" config.serviceConfig.GroupName}
              ${xmlMapAttr (xmlMapAttrs xmlBool) "inetdCompatibility" config.serviceConfig.inetdCompatibility}
              ${xmlMapAttr (xmlMap xmlString) "LimitLoadToHosts" config.serviceConfig.LimitLoadToHosts}
              ${xmlMapAttr (xmlMap xmlString) "LimitLoadFromHosts" config.serviceConfig.LimitLoadFromHosts}
              ${xmlMapAttr xmlString "LimitLoadToSessionType" config.serviceConfig.LimitLoadToSessionType}
              ${xmlMapAttr xmlString "Program" config.serviceConfig.Program}
              ${xmlMapAttr (xmlMap xmlString) "ProgramArguments" config.serviceConfig.ProgramArguments}
              ${xmlMapAttr xmlBool "EnableGlobbing" config.serviceConfig.EnableGlobbing}
              ${xmlMapAttr xmlBool "EnableTransactions" config.serviceConfig.EnableTransactions}
              ${xmlMapAttr xmlBool "OnDemand" config.serviceConfig.OnDemand}
              ${xmlMapAttr xmlBool "KeepAlive" config.serviceConfig.KeepAlive}
              ${xmlMapAttr xmlBool "RunAtLoad" config.serviceConfig.RunAtLoad}
              ${xmlMapAttr xmlString "RootDirectory" config.serviceConfig.RootDirectory}
              ${xmlMapAttr xmlString "WorkingDirectory" config.serviceConfig.WorkingDirectory}
              ${xmlMapAttr (xmlMapAttrs xmlString) "EnvironmentVariables" config.serviceConfig.EnvironmentVariables}
              ${xmlMapAttr xmlInt "Umask" config.serviceConfig.Umask}
              ${xmlMapAttr xmlInt "TimeOut" config.serviceConfig.TimeOut}
              ${xmlMapAttr xmlInt "ExitTimeOut" config.serviceConfig.ExitTimeOut}
              ${xmlMapAttr xmlInt "ThrottleInterval" config.serviceConfig.ThrottleInterval}
              ${xmlMapAttr xmlBool "InitGroups" config.serviceConfig.InitGroups}
              ${xmlMapAttr (xmlMap xmlString) "WatchPaths" config.serviceConfig.WatchPaths}
              ${xmlMapAttr (xmlMap xmlString) "QueueDirectories" config.serviceConfig.QueueDirectories}
              ${xmlMapAttr xmlBool "StartOnMount" config.serviceConfig.StartOnMount}
              ${xmlMapAttr xmlInt "StartInterval" config.serviceConfig.StartInterval}
              ${xmlMapAttr (xmlMapAttrs xmlInt) "StartCalendarInterval" config.serviceConfig.StartCalendarInterval}
              ${xmlMapAttr xmlString "StandardInPath" config.serviceConfig.StandardInPath}
              ${xmlMapAttr xmlString "StandardOutPath" config.serviceConfig.StandardOutPath}
              ${xmlMapAttr xmlString "StandardErrorPath" config.serviceConfig.StandardErrorPath}
              ${xmlMapAttr xmlBool "Debug" config.serviceConfig.Debug}
              ${xmlMapAttr xmlBool "WaitForDebugger" config.serviceConfig.WaitForDebugger}
              ${xmlMapAttr (xmlMapAttrs xmlInt) "SoftResourceLimits" config.serviceConfig.SoftResourceLimits}
              ${xmlMapAttr (xmlMapAttrs xmlInt) "HardResourceLimits" config.serviceConfig.HardResourceLimits}
              ${xmlMapAttr xmlInt "Nice" config.serviceConfig.Nice}
              ${xmlMapAttr xmlString "ProcessType" config.serviceConfig.ProcessType}
              ${xmlMapAttr xmlBool "AbandonProcessGroup" config.serviceConfig.AbandonProcessGroup}
              ${xmlMapAttr xmlBool "LowPriorityIO" config.serviceConfig.LowPriorityIO}
              ${xmlMapAttr xmlBool "LaunchOnlyOnce" config.serviceConfig.LaunchOnlyOnce}
              ${xmlMapAttr (xmlMapAttrs xmlBool) "MachServices" config.serviceConfig.MachServices}
            </dict>
          </plist>
        '';
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

    system.activationScripts.launchd.text = ''
      # Set up launchd services in /Library/LaunchAgents, /Library/LaunchDaemons and ~/Library/LaunchAgents
      echo "setting up launchd services..."
      echo "TODO"
      exit 2
    '';

  };
}
