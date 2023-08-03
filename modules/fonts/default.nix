{ config, lib, pkgs, ... }:

let
  cfg = config.fonts;
in

{
  imports = [
    (lib.mkRenamedOptionModule [ "fonts" "enableFontDir" ] [ "fonts" "fontDir" "enable" ])
  ];

  options = {
    fonts.fontDir.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Whether to enable font management and install configured fonts to
        {file}`/Library/Fonts`.

        NOTE: removes any manually-added fonts.
      '';
    };

    fonts.fonts = lib.mkOption {
      type = lib.types.listOf lib.types.path;
      default = [ ];
      example = lib.literalExpression "[ pkgs.dejavu_fonts ]";
      description = ''
        List of fonts to install.

        Fonts present in later entries override those with the same filenames
        in previous ones.
      '';
    };
  };

  config = {

    system.build.fonts = pkgs.runCommand "fonts"
      { preferLocalBuild = true; }
      ''
        mkdir -p $out/Library/Fonts
        font_regexp='.*\.\(ttf\|ttc\|otf\|dfont\)'
        while IFS= read -rd "" f; do
          ln -sf "$f" "$out/Library/Fonts"
        done < <(
          find -L ${lib.escapeShellArgs cfg.fonts} \
            -type f \
            -regex "$font_regexp" \
            -print0
        )
      '';

    system.activationScripts.fonts.text = lib.optionalString cfg.fontDir.enable ''
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

      if [[ "`sw_vers -productVersion`" < "13.0" ]]; then
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
      fi
    '';

  };
}
