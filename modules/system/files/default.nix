{ config, lib, pkgs, ... }:

let
  text = import ./write-text.nix {
    inherit lib;
    mkTextDerivation = name: text: pkgs.writeText "system-file-${name}" text;
  };

  rawFiles = lib.filterAttrs (n: v: v.enable) config.system.file;

  files = lib.mapAttrs' (name: value: lib.nameValuePair value.target {
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

  # The linker tests require Python 3.12 because they subclass pathlib.Path, so we set that as the minimum version
  linker = lib.getExe (pkgs.callPackage ./linker (lib.optionalAttrs (pkgs.python3Packages.pythonOlder "3.12") { python3Packages = pkgs.python312Packages; }));
in

{
  options = {
    system.file = lib.mkOption {
      type = lib.types.attrsOf (lib.types.submodule text);
      default = {};
      description = ''
        Set of files that have to be linked/copied out of the Nix store.
      '';
    };
  };

  config = {
    system.build.files = linksJSON;

    system.activationScripts.filesChecks.text = ''
      echo "checking for systemwide file collisions..." >&2
      OLD=/run/current-system/links.json
      if [ ! -e "$OLD" ]; then
        OLD=${emptyJSON}
      fi
      CHECK_ONLY=1 ${linker} "$OLD" "$systemConfig"/links.json
    '';

    system.activationScripts.files.text = ''
      echo "setting up files systemwide..." >&2
      OLD=/run/current-system/links.json
      if [ ! -e "$OLD" ]; then
        OLD=${emptyJSON}
      fi
      ${linker} "$OLD" "$systemConfig"/links.json
    '';
  };
}
