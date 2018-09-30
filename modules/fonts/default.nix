{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.fonts;
  fontFiles = env: with builtins;
  filter (n: match ".*\\.ttf" n != null) (attrNames (readDir "${env}/share/fonts/truetype/"));
in {
  options = {
    fonts = {
      fonts = mkOption {
        type = types.listOf types.path;
        default = [];
        example = literalExample "[ pkgs.dejavu_fonts ]";
        description = "List of primary font paths.";
      };
    };
  };
  
  config = {
    system.build.fonts = pkgs.buildEnv {
      name = "system-fonts";
      paths = cfg.fonts;
      pathsToLink = "/share/fonts";
    };
    system.activationScripts.fonts.text = ''
      # Set up fonts.
      echo "resetting fonts..." >&2
      fontrestore default -n 2>&1 | grep -o '/Library/Fonts/.*' | tr '\n' '\0' | xargs -0 rm || true
      echo "updating fonts..." >&2
      ${concatMapStrings (font: "ln -fn '${config.system.build.fonts}/share/fonts/truetype/${font}' '/Library/Fonts/${font}'\n")
      (fontFiles config.system.build.fonts)}
   '';
    environment.pathsToLink = [ "/share/fonts" ];
  };

}
