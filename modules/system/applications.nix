{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.system;

  packageUsers = filterAttrs (_: u: u.packages != []) config.users.users;

  userApplications = mapAttrs (name: { packages, home, ... }: {
    home = home;
    applications = pkgs.buildEnv {
      name = "${name}-applications";
      paths = packages;
      pathsToLink = "/Applications";
    };
  }) packageUsers;

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
      echo "setting up /Applications/Nix Apps..." >&2

      if [ ! -e /Applications/Nix\ Apps -o -L /Applications/Nix\ Apps ]; then
        ln -sfn ${cfg.build.applications}/Applications /Applications/Nix\ Apps
      else
        echo "warning: /Applications/Nix Apps is a directory, skipping App linking..." >&2
      fi

      ${concatStringsSep "\n" (mapAttrsToList (name: { applications, home }: ''
        # Set up applications for ${name}
        echo "setting up ${home}/Applications"

        if [ ! -e ${home}/Applications -o -L ${home}/Applications ]; then
          ln -sfn ${applications}/Applications ${home}/Applications
        elif [ ! -e ${home}/Applications/Nix\ Apps -o -L ${home}/Applications/Nix\ Apps ]; then
          ln -sfn ${applications}/Applications ${home}/Applications/Nix\ Apps
        else
          echo "warning: ${home}/Applications and ${home}/Applications/Nix Apps are directories, skipping App linking..." >&2
        fi
      '') userApplications)}
    '';

  };
}
