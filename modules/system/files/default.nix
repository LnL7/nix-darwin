{ config, lib, pkgs, ... }:

with lib;

let

  text = import ./write-text.nix {
    inherit lib;
    mkTextDerivation = name: text: pkgs.writeText "system-file-${name}" text;
  };

  rawFiles = filterAttrs (n: v: v.enable) config.system.file;

  files = mapAttrs' (name: value: nameValuePair value.target {
    type = "link";
    inherit (value) source;
  }) rawFiles;

  linksJSON = pkgs.writeText "system-files.json" (builtins.toJSON {
    version = 1;
    inherit files;
  });

  emptyJSON = pkgs.writeText "empty-files.json" (builtins.toJSON {
    version = 1;
    files = {};
  });

  python = lib.getExe pkgs.python3;
  linker = ./linker.py;
in

{
  options = {
    system.file = mkOption {
      type = types.attrsOf (types.submodule text);
      default = {};
      description = ''
        Set of files that have to be linked/copied out of the Nix store.
      '';
    };
  };

  config = {
    system.build.files = linksJSON;

    system.activationScripts.filesChecks.text = ''
      OLD=/run/current-system/links.json
      if [ ! -e "$OLD" ]; then
        OLD=${emptyJSON}
      fi
      CHECK_ONLY=1 ${python} ${linker} "$OLD" "$systemConfig"/links.json
    '';

    system.activationScripts.files.text = ''
      OLD=/run/current-system/links.json
      if [ ! -e "$OLD" ]; then
        OLD=${emptyJSON}
      fi
      ${python} ${linker} "$OLD" "$systemConfig"/links.json
    '';
  };
}
