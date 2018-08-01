{ lib }:

with lib;

let

  attrFilter = name: value: name != "_module" && value != null;

in

rec {

  toPLIST = x: inPLISTDocument ("\n" + pprExpr "" x + "\n");

  inPLISTDocument = x: ''
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">${x}</plist>'';

  pprExpr = ind: x:
    if isNull x then "" else
    if isBool x then pprBool ind x else
    if isInt x then pprInt ind x else
    if isString x then pprStr ind x else
    if isList x then pprList ind x else
    if isCustomType x then pprCustomType ind x else
    if isAttrs x then pprAttrs ind x else
    throw "invalid plist type";

  pprLiteral = ind: x: ind + x;
  pprTag = tag: ind: x: pprLiteral ind "<${tag}>${x}</${tag}>";
  pprTagNewlines = tag: f: ind: x: concatStringsSep "\n" [
    (pprLiteral ind "<${tag}>")
    (f ind x)
    (pprLiteral ind "</${tag}>")
  ];

  pprBool = ind: x: pprLiteral ind (if x then "<true/>" else "<false/>");
  pprInt = ind: x: pprTag "integer" ind (toString x);
  pprStr = pprTag "string";
  pprKey = pprTag "key";

  pprIndent = ind: (pprExpr "\t${ind}");

  pprList = pprTagNewlines "array" pprItem;
  pprItem = ind: concatMapStringsSep "\n" (pprIndent ind);

  pprAttrs = pprTagNewlines "dict" pprAttr;
  pprAttr = ind: x: concatStringsSep "\n" (flatten (mapAttrsToList (name: value: optional (attrFilter name value) [
    (pprKey "\t${ind}" name)
    (pprExpr "\t${ind}" value)
  ]) x));

  # Custom types not directly supported by nix.
  #   Custom types are encoded as normal attrsets that contain a specially named key.
  pprCustomType = ind: x:
    let tag = x.${plistCustomTypeKey}; in
    if tag == null then pprLiteral ind x.value else
    pprTag tag ind (if isString x.value then x.value else toString x.value);

  plistCustomTypeKey = "!__custom_type";  # a relatively unique attribute key to detect custom types
  isCustomType = x: isAttrs x && hasAttr plistCustomTypeKey x;

  types = rec {
    custom = type: value: { ${plistCustomTypeKey} = type; inherit value; };
    raw = custom null;
    real = custom "real";
  };
}
