{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.system;

  text = import ../system/write-text.nix {
    inherit lib;
    mkTextDerivation = pkgs.writeText;
  };

  launchAgents = filter (f: f.enable) (attrValues config.environment.launchAgents);
  launchDaemons = filter (f: f.enable) (attrValues config.environment.launchDaemons);

in

{
  options = {

    environment.launchAgents = mkOption {
      type = types.loaOf (types.submodule text);
      default = {};
      description = ''
        Set of files that have to be linked in <filename>/Library/LaunchAgents</filename>.
      '';
    };

    environment.launchDaemons = mkOption {
      type = types.loaOf (types.submodule text);
      default = {};
      description = ''
        Set of files that have to be linked in <filename>/Library/LaunchDaemons</filename>.
      '';
    };

  };

  config = {

    system.build.launchd = pkgs.runCommand "launchd" {} ''
      mkdir -p $out/Library/LaunchAgents $out/Library/LaunchDaemons
      cd $out/Library/LaunchAgents
      ${concatMapStringsSep "\n" (attr: "ln -s '${attr.source}' '${attr.target}'") launchAgents}
      cd $out/Library/LaunchDaemons
      ${concatMapStringsSep "\n" (attr: "ln -s '${attr.source}' '${attr.target}'") launchDaemons}
    '';

    system.activationScripts.launchd.text = ''
      # Set up launchd services in /Library/LaunchAgents and /Library/LaunchDaemons
      echo "setting up launchd services..."

      ${concatMapStringsSep "\n" (attr: "launchctl unload '/Library/LaunchAgents/${attr.target}'") launchAgents}
      ${concatMapStringsSep "\n" (attr: "launchctl unload '/Library/LaunchDaemons/${attr.target}'") launchDaemons}
      ${concatMapStringsSep "\n" (attr: "cp -f '${cfg.build.launchd}/Library/LaunchAgents/${attr.target}' '/Library/LaunchAgents/${attr.target}'") launchAgents}
      ${concatMapStringsSep "\n" (attr: "cp -f '${cfg.build.launchd}/Library/LaunchDaemons/${attr.target}' '/Library/LaunchDaemons/${attr.target}'") launchDaemons}
      ${concatMapStringsSep "\n" (attr: "launchctl load '/Library/LaunchAgents/${attr.target}'") launchAgents}
      ${concatMapStringsSep "\n" (attr: "launchctl load '/Library/LaunchDaemons/${attr.target}'") launchDaemons}
    '';

  };
}
