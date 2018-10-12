{ config, pkgs, ... }:

let
  font = pkgs.runCommand "font-0.0.0" {} ''
    mkdir -p $out/share/fonts
    touch $out/share/fonts/Font.ttf
  '';
in

{
  fonts.enableFontDir = true;
  fonts.fonts = [ font ];
 
  test = ''
    echo checking installed fonts >&2
    grep -o "fontrestore default -n" ${config.out}/activate
    grep -o "ln -fn '/run/current-system/sw/share/fonts/Font.ttf' '/Library/Fonts/Font.ttf'" ${config.out}/activate
  '';
}

