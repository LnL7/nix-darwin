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
      echo "setting up /Applications/Nix Apps..." >&2

      # Clean up for links created at the old location in HOME
      if [ -L ~/Applications
           -a $(readlink ~/Applications | grep --quiet
                 '/nix/store/.*-system-applications/Applications')
         ]
        rm ~/Applications
      elif [ -L '~/Applications/Nix Apps'
             -a $(readlink '~/Applications/Nix Apps' | grep --quiet
                   '/nix/store/.*-system-applications/Applications')
           ]
        rm '~/Applications/Nix Apps'
      fi

      if [ ! -e '/Applications/Nix Apps' -o -L '/Applications/Nix Apps' ]; then
        ln -sfn ${cfg.build.applications}/Applications '/Applications/Nix Apps'
      else
        echo "warning: /Applications/Nix Apps is not owned by nix-darwin, skipping App linking..." >&2
      fi
    '';

  };
}
