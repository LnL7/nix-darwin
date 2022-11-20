{ config, lib, pkgs, ... }:

with lib;

let

  text = import ../lib/write-text.nix {
    inherit lib;
    mkTextDerivation = name: text: pkgs.writeText "etc-${name}" text;
  };

  hasDir = path: length (splitString "/" path) > 1;

  etc = filter (f: f.enable) (attrValues config.environment.etc);
  etcDirs = filter (attr: hasDir attr.target) (attrValues config.environment.etc);
in let
  activationScriptFile = pkgs.substituteAll {
    src = ./etc.sh;
    etcSha256Hashes = concatMapStringsSep "\n" (attr: "etcSha256Hashes['/etc/${attr.target}']='${concatStringsSep " " attr.knownSha256Hashes}'") etc;
  };
in {
  options = {

    environment.etc = mkOption {
      type = types.attrsOf (types.submodule text);
      default = { };
      description = ''
        Set of files that have to be linked in <filename>/etc</filename>.
      '';
    };

  };

  config = {

    system.build.etc = pkgs.runCommand "etc"
      { preferLocalBuild = true; }
      ''
        mkdir -p $out/etc
        cd $out/etc
        ${concatMapStringsSep "\n" (attr: "mkdir -p $(dirname '${attr.target}')") etc}
        ${concatMapStringsSep "\n" (attr: "ln -s '${attr.source}' '${attr.target}'") etc}
      '';

    system.activationScripts.etc.text = readFile activationScriptFile;

  };
}
