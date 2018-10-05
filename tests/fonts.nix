{ config, pkgs, ... }:

let
  fonts = pkgs.runCommand "fonts-0.0.0" {} "mkdir -p $out";
in {
  fonts = {
    enableFontDir = true;
    fonts = [ pkgs.dejavu_fonts ];
  };
 
  test = ''
    echo checking installed fonts >&2
    grep -o "fontrestore default -n" ${config.out}/activate
    grep -o "/share/fonts/truetype/DejaVuSans.ttf' '/Library/Fonts/DejaVuSans.ttf'" ${config.out}/activate
  '';
}

