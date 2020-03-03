{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.fonts;
in

{
  options = {
    fonts.enableFontDir = mkOption {
      default = false;
      description = ''
        Whether to enable font management and install configured fonts to
        <filename>/Library/Fonts</filename>.

        NOTE: removes any manually-added fonts.
      '';
    };

    fonts.fonts = mkOption {
      type = types.listOf types.path;
      default = [];
      example = literalExample "[ pkgs.dejavu_fonts ]";
      description = "List of fonts to install.";
    };
  };

  config = {

    system.build.fonts = pkgs.runCommandNoCC "fonts"
      { paths = cfg.fonts; preferLocalBuild = true; }
      ''
        mkdir -p $out/Library/Fonts
        for path in $paths; do
            find -L $path/share/fonts -type f -print0 | while IFS= read -rd "" f; do
                ln -s "$f" $out/Library/Fonts
            done
        done
      '';

    system.activationScripts.fonts.text = optionalString cfg.enableFontDir ''
      # Set up fonts.
      echo "configuring fonts..." >&2
      find -L "$systemConfig/Library/Fonts" -type f -print0 | while IFS= read -rd "" l; do
          font=''${l##*/}
          f=$(readlink -f "$l")
          if [ ! -e "/Library/Fonts/$font" ]; then
              echo "updating font $font..." >&2
              ln -fn -- "$f" /Library/Fonts 2>/dev/null || {
                echo "Could not create hard link. Nix is probably on another filesystem. Copying the font instead..." >&2
                rsync -az --inplace "$f" /Library/Fonts
              }
          fi
      done

      fontrestore default -n 2>&1 | while read -r f; do
          case $f in
              /Library/Fonts/*)
                  font=''${f##*/}
                  if [ ! -e "$systemConfig/Library/Fonts/$font" ]; then
                      echo "removing font $font..." >&2
                      rm "/Library/Fonts/$font"
                  fi
                  ;;
              /*)
                  # ignoring unexpected fonts
                  ;;
          esac
      done
    '';

  };
}
