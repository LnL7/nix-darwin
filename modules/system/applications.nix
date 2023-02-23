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

      ourLink () {
        local link
        link=$(readlink "$1")
        [ -L "$1" ] && [ "''${link#*-}" = 'system-applications/Applications' ]
      }

      # Clean up for links created at the old location in HOME
      if ourLink ~/Applications; then
        rm ~/Applications
      elif ourLink ~/Applications/'Nix Apps'; then
        rm ~/Applications/'Nix Apps'
      fi

      if [ ! -e '/Applications/Nix Apps' ] \
         || ourLink '/Applications/Nix Apps'; then
        ln -sfn ${cfg.build.applications}/Applications '/Applications/Nix Apps'
      else
        echo "warning: /Applications/Nix Apps is not owned by nix-darwin, skipping App linking..." >&2
      fi
    '';

  };
}
