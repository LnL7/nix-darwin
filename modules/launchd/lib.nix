{ lib }:

with lib;

let

  attrFilter = name: value: name != "_module" && value != null;

in

rec {

  toPLIST = x: ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
  '' + pprExpr "" x
     + "\n</plist>";

  pprExpr = ind: x:
    if isNull x then "" else
    if isBool x then pprBool ind x else
    if isInt x then pprInt ind x else
    if isString x then pprStr ind x else
    if isList x then pprList ind x else
    if isAttrs x then pprAttrs ind x else
    throw "invalid plist type";

  pprLiteral = ind: x: ind + x;

  pprBool = ind: x: pprLiteral ind  (if x then "<true/>" else "<false/>");
  pprInt = ind: x: pprLiteral ind "<integer>${toString x}</integer>";
  pprStr = ind: x: pprLiteral ind "<string>${x}</string>";
  pprKey = ind: x: pprLiteral ind "<key>${x}</key>";

  pprIndent = ind: (pprExpr "\t${ind}");

  pprItem = ind: concatMapStringsSep "\n" (pprIndent ind);

  pprList = ind: x: concatStringsSep "\n" [
    (pprLiteral ind "<array>")
    (pprItem ind x)
    (pprLiteral ind "</array>")
  ];

  pprAttrs = ind: x: concatStringsSep "\n" [
    (pprLiteral ind "<dict>")
    (pprAttr ind x)
    (pprLiteral ind "</dict>")
  ];

  pprAttr = ind: x: concatStringsSep "\n" (flatten (mapAttrsToList (name: value: optional (attrFilter name value) [
    (pprKey "\t${ind}" name)
    (pprExpr "\t${ind}" value)
  ]) x));

}
