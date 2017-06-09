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

      if [ ! -e ~/Applications -o -L ~/Applications ]; then
        ln -sfn ${cfg.build.applications}/Applications ~/Applications
      elif [ ! -e ~/Applications/Nix\ Apps -o -L ~/Applications/Nix\ Apps ]; then
        ln -sfn ${cfg.build.applications}/Applications ~/Applications/Nix\ Apps
      else
        echo "warning: ~/Applications and ~/Applications/Nix Apps are directories, skipping App linking..." >&2
      fi
    '';

  };
}
