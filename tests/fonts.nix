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
    echo "checking fonts in /Library/Fonts" >&2
    test -e ${config.out}/Library/Fonts/Font.ttf

    echo "checking activation of fonts in /activate" >&2
    grep "fontrestore default -n 2>&1" ${config.out}/activate
    grep 'ln -fn ".*" /Library/Fonts' ${config.out}/activate || grep 'rsync -az --inplace ".*" /Library/Fonts' ${config.out}/activate
    grep 'rm "/Library/Fonts/.*"' ${config.out}/activate
  '';
}

