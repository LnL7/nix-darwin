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
      mkdir -p ~/Applications

      echo "TODO: REMOVE THIS"
      ls -la ~/Applications

      nix_apps=~/Applications/Nix\ Apps
      if [ -d  "$nix_apps" ]; then
        # If there's already a folder, delete it in order to create a symlink
        rm -rf "$nix_apps"
      fi

      ln -sfn ${cfg.build.applications}/Applications "$nix_apps"
    '';

  };
}
