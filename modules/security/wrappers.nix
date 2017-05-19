{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.security;

  parentWrapperDir = dirOf cfg.wrapperDir;

  mkCodesignProgram =
    { program
    , source
    , codesign
    , permissions ? "u+rx,g+x,o+x"
    , ...
    }:
    ''
      cp "${source}" $wrapperDir/${program}

      # Codesign the wrapper program.
      codesign -s "${cfg.codesignIdentity}" $wrapperDir/${program}

      # Prevent races
      chmod 0000 $wrapperDir/${program}
      chmod "u-s,g-s,${permissions}" $wrapperDir/${program}
    '';

  mkWrappedPrograms =
    builtins.map
      (s: if s.codesign
          then mkCodesignProgram s
          else ""
      ) (attrValues cfg.wrappers);
in
{
  options = {
    security.codesignIdentity = mkOption {
      type = types.str;
      default = "";
      description = "Identity to use for codesigning.";
    };

    security.wrappers = mkOption {
      type = types.attrsOf (types.submodule (
        { name, config, ... }:
        { options = {
            source  = mkOption {
              type = types.path;
              description = "The absolute path to the program to be wrapped.";
            };

            program = mkOption {
              type = types.str;
              description = "Name of the program to wrap.";
            };

            codesign = mkOption {
              type = types.bool;
              default = false;
              description = "Whether to codesign the wrapper.";
            };

            permissions = mkOption {
              type = types.str;
              default = "u+rx,g+x,o+x";
              description = "What permissions to set on the wrapper.";
            };
          };

          config = {
            program = mkDefault name;
          };
        }));
      default = {};
      example = literalExample ''
        { gdb.source = "''${pkgs.gdb}/bin/gdb";
          gdb.codesign = true;
        }
      '';
    };

    security.wrapperDir = mkOption {
      internal = true;
      type = types.path;
      default = "/run/wrappers/bin";
      description = ''
        This option defines the path to the wrapper programs. It
        should not be overriden.
      '';
    };
  };

  config = {

    environment.extraInit = ''
      # Wrappers override other bin directories.
      export PATH="${cfg.wrapperDir}:$PATH"
    '';

    system.activationScripts.wrappers.text = ''
      echo "setting up wrappers..." >&2
      if ! test -e /run/wrappers; then mkdir /run/wrappers; fi

      # We want to place the tmpdirs for the wrappers to the parent dir.
      wrapperDir=$(mktemp --directory --tmpdir="${parentWrapperDir}" wrappers.XXXXXXXXXX)
      chmod a+rx $wrapperDir

      ${concatStringsSep "\n" mkWrappedPrograms}

      if test -L ${cfg.wrapperDir}; then
        # Atomically replace the symlink
        # See https://axialcorps.com/2013/07/03/atomically-replacing-files-and-directories/
        old=$(readlink -f ${cfg.wrapperDir})
        ln --symbolic --force --no-dereference $wrapperDir ${cfg.wrapperDir}-tmp
        mv --no-target-directory ${cfg.wrapperDir}-tmp ${cfg.wrapperDir}
        rm --force --recursive $old
      else
        # For initial setup
        ln --symbolic $wrapperDir ${cfg.wrapperDir}
      fi
    '';

  };
}
