{
  config,
  lib,
  pkgs,
  ...
}:

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

      ourfolder () {
        local marker
        marker=$(xattr -p org.nix-darwin "$1" 2>/dev/null)
        [ "$marker" = 'generated' ]
      }

      targetFolder='/Applications/Nix Apps'

      # Clean up for links created at the old location in /Applications
      if [ -e "$targetFolder" ] && ourLink "$targetFolder"; then
        rm "$targetFolder"
      fi

      if [ -e "$targetFolder" ] && ! ourFolder "$targetFolder"; then
        echo "warning: $targetFolder is not owned by nix-darwin, skipping App linking..." >&2
      else
        # create and mark folder
        mkdir -p "$targetFolder"
        xattr -w org.nix-darwin generated "$targetFolder"

        rsyncFlags=(
          --archive
          --checksum
          --chmod=-w
          --copy-unsafe-links
          --delete
          --no-group
          --no-owner
        )

        # sync applications
        ${lib.getBin pkgs.rsync}/bin/rsync \
            -v "''${rsyncFlags[@]}" \
            ${cfg.build.applications}/Applications/ "$targetFolder"
      fi
    '';

  };
}
