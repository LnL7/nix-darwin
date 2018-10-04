{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.fonts;
  printLinks = dir: with builtins;
    let readDirsRec = path: let
      home = readDir path;
      list = mapAttrsToList (name: type:
        let newPath = "${path}/${name}";
        in if (type == "directory" || type == "symlink") && !(hasSuffix ".ttf" name) then readDirsRec newPath else [ newPath ]) home;
      in flatten list;
    fontFiles = dir: filter (name: hasSuffix ".ttf" name) (readDirsRec dir);
    print = font: "ln -fn '${font}' '/Library/Fonts/${baseNameOf font}'";
    in concatMapStringsSep "\n" print (fontFiles dir);
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
      ${printLinks config.system.build.fonts}
   '';
    environment.pathsToLink = [ "/share/fonts" ];
  };
}
