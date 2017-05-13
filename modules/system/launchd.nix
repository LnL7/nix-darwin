{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.system;

  text = import ../lib/write-text.nix {
    inherit lib;
    mkTextDerivation = pkgs.writeText;
  };

  launchdActivation = basedir: target: ''
    if ! diff '${cfg.build.launchd}/Library/${basedir}/${target}' '/Library/${basedir}/${target}' &> /dev/null; then
      if test -f '/Library/${basedir}/${target}'; then
        echo "reloading service $(basename ${target} .plist)" >&2
        launchctl unload -w '/Library/${basedir}/${target}' || true
      else
        echo "creating service $(basename ${target} .plist)" >&2
      fi
      cp -f '${cfg.build.launchd}/Library/${basedir}/${target}' '/Library/${basedir}/${target}'
      launchctl load -w '/Library/${basedir}/${target}'
    fi
  '';

  userLaunchdActivation = target: ''
    if ! diff ${cfg.build.launchd}/user/Library/LaunchAgents/${target} ~/Library/LaunchAgents/${target} &> /dev/null; then
      if test -f ~/Library/LaunchAgents/${target}; then
        echo "reloading user service $(basename ${target} .plist)" >&2
        launchctl unload -w ~/Library/LaunchAgents/${target} || true
      else
        echo "creating user service $(basename ${target} .plist)" >&2
      fi
      cp -f '${cfg.build.launchd}/user/Library/LaunchAgents/${target}' ~/Library/LaunchAgents/${target}
      launchctl load -w ~/Library/LaunchAgents/${target}
    fi
  '';

  launchAgents = filter (f: f.enable) (attrValues config.environment.launchAgents);
  launchDaemons = filter (f: f.enable) (attrValues config.environment.launchDaemons);
  userLaunchAgents = filter (f: f.enable) (attrValues config.environment.userLaunchAgents);

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

    environment.userLaunchAgents = mkOption {
      type = types.loaOf (types.submodule text);
      default = {};
      description = ''
        Set of files that have to be linked in <filename>~/Library/LaunchAgents</filename>.
      '';
    };

  };

  config = {

    system.build.launchd = pkgs.runCommand "launchd" {} ''
      mkdir -p $out/Library/LaunchAgents $out/Library/LaunchDaemons $out/user/Library/LaunchAgents
      cd $out/Library/LaunchAgents
      ${concatMapStringsSep "\n" (attr: "ln -s '${attr.source}' '${attr.target}'") launchAgents}
      cd $out/Library/LaunchDaemons
      ${concatMapStringsSep "\n" (attr: "ln -s '${attr.source}' '${attr.target}'") launchDaemons}
      cd $out/user/Library/LaunchAgents
      ${concatMapStringsSep "\n" (attr: "ln -s '${attr.source}' '${attr.target}'") userLaunchAgents}
    '';

    system.activationScripts.launchd.text = ''
      # Set up launchd services in /Library/LaunchAgents and /Library/LaunchDaemons
      echo "setting up launchd services..."

      ${concatMapStringsSep "\n" (attr: launchdActivation "LaunchAgents" attr.target) launchAgents}
      ${concatMapStringsSep "\n" (attr: launchdActivation "LaunchDaemons" attr.target) launchDaemons}

      for f in $(ls /run/current-system/Library/LaunchAgents); do
        if test ! -e "${cfg.build.launchd}/Library/LaunchAgents/$f"; then
          echo "removing service $(basename $f .plist)" >&2
          launchctl unload -w "/Library/LaunchAgents/$f" || true
          if test -e "/Library/LaunchAgents/$f"; then rm -f "/Library/LaunchAgents/$f"; fi
        fi
      done

      for f in $(ls /run/current-system/Library/LaunchDaemons); do
        if test ! -e "${cfg.build.launchd}/Library/LaunchDaemons/$f"; then
          echo "removing service $(basename $f .plist)" >&2
          launchctl unload -w "/Library/LaunchDaemons/$f" || true
          if test -e "/Library/LaunchDaemons/$f"; then rm -f "/Library/LaunchDaemons/$f"; fi
        fi
      done
    '';

    system.activationScripts.userLaunchd.text = ''
      # Set up user launchd services in ~/Library/LaunchAgents
      echo "setting up user launchd services..."

      ${concatMapStringsSep "\n" (attr: userLaunchdActivation attr.target) userLaunchAgents}

      for f in $(ls /run/current-system/user/Library/LaunchAgents); do
        if test ! -e "${cfg.build.launchd}/user/Library/LaunchAgents/$f"; then
          echo "removing user service $(basename $f .plist)" >&2
          launchctl unload -w ~/Library/LaunchAgents/$f || true
          if test -e ~/Library/LaunchAgents/$f; then rm -f ~/Library/LaunchAgents/$f; fi
        fi
      done
    '';

  };
}
