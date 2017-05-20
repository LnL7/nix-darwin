{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.system;

in

{
  options = {
  };

  config = {

    system.build.applications = pkgs.buildEnv {
      name = "system-applications";
      paths = config.environment.systemPackages;
      pathsToLink = "/Applications";
    };

    system.activationScripts.applications.text = ''
      # Set up applications.
      echo "setting up ~/Applications..." >&2

      if [ -d ~/Applications ]; then
        echo "warning: ~/Applications is a directory, skipping..." >&2
      else
        ln -sfn ${cfg.build.applications}/Applications ~/Applications
      fi
    '';

  };
}
