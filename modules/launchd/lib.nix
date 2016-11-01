{ lib }:

with lib;

rec {

  xmlMap = f: xs: ''
    <array>
    ${concatMapStringsSep "\n" f xs}
    </array>
  '';

  xmlMapAttrs = f: attr: ''
    <dict>
    ${concatStringsSep "\n" (mapAttrsFlatten (xmlMapAttr f) attr)}
    </dict>
  '';

  xmlMapAttr = f: n: v: optionalString (v != null) ''
    <key>${n}</key>
    ${f v}
  '';

  xmlBool = x: if x then "<true/>" else "<false/>";
  xmlInt = x: "<integer>${toString x}</integer>";
  xmlString = x: "<string>${x}</string>";

}
