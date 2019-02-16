{ config, lib, pkgs, ... }:

with lib;
with builtins;

let
  cfg = config.fonts;
  readDirsRec = path: let
    home = readDir path;
    list = mapAttrsToList (name: type:
      let newPath = "${path}/${name}";
      in if (type == "directory" || type == "symlink") && !(isFont name) then readDirsRec newPath else [ newPath ]) home;
    in flatten list;
  isFont = name: let
    fontExt = [ ".ttf" ".otf" ];
    hasExt = exts: name: foldl' (acc: ext: (hasSuffix ext name) || acc) false exts;
    in hasExt fontExt name;
  fontFiles = dir: filter isFont (readDirsRec dir);
  libraryLink = font: "ln -fn '/run/current-system/sw/share/fonts/${baseNameOf font}' '/Library/Fonts/${baseNameOf font}'";
  outLink = font: "ln -sfn -t $out/share/fonts/ '${font}'";
  fontLinks = link: dir: concatMapStringsSep "\n" link (fontFiles dir);
  systemFontsDir = pkgs.runCommand "systemFontsDir" {} ''
    mkdir -p "$out/share/fonts"
    echo ${toString config.fonts.fonts}
    ${concatMapStringsSep "\n" (fontLinks outLink) config.fonts.fonts}
  '';
in {
  options = {
    fonts = {
      enableFontDir = mkOption {
        default = false;
        description = ''
          Whether to enable font directory management and link all fonts in <filename>/run/current-system/sw/share/fonts</filename>.
          Important: removes all manually-added fonts.
        '';
      };
      fonts = mkOption {
        type = types.listOf types.path;
        default = [];
        example = literalExample "[ pkgs.dejavu_fonts ]";
        description = "List of primary font paths.";
      };
    };
  };

  config = {
    system.activationScripts.fonts.text = "" + optionalString cfg.enableFontDir ''
      # Set up fonts.
      echo "resetting fonts..." >&2
      fontrestore default -n 2>&1 | grep -o '^/Library/Fonts/.*' | tr '\n' '\0' | xargs -0 rm || true
      echo "updating fonts..." >&2
      ${fontLinks libraryLink systemFontsDir}
    '';
    environment.systemPackages = [ systemFontsDir ];
    environment.pathsToLink = [ "/share/fonts" ];
  };
}
