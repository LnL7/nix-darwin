{ config, lib, pkgs, ... }:

let
  cfg = config.security;

  parentWrapperDir = dirOf cfg.wrapperDir;

  wrapperType = lib.types.submodule ({ name, config, ... }: {
    options = with lib; {
      source = mkOption {
        type = types.path;
        description = mdDoc "The absolute path to the program to be wrapped.";
      };
      program = mkOption {
        type = with types; nullOr str;
        default = name;
        description = mdDoc "The name of the wrapper program. Defaults to the attribute name.";
      };
      owner = mkOption {
        type = types.str;
        description = mdDoc "The owner of the wrapper program.";
      };
      group = mkOption {
        type = types.str;
        description = mdDoc "The group of the wrapper program.";
      };
      permissions = mkOption {
        type = types.str;
        default = "u+rx,g+x,o+x";
        description = mdDoc "The permissions to set on the wrapper.";
      };
      setuid = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc "Whether to add the setuid bit to the wrapper program.";
      };
      setgid = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc "Whether to add the setgid bit to the wrapper program.";
      };
      codesign = mkOption {
        type = types.bool;
        default = false;
        description = mdDoc "Whether to codesign the wrapper program.";
      };
    };
  });

  mkWrappedPrograms =
    builtins.map
      (opts: mkWrapper opts)
      (builtins.attrValues cfg.wrappers);

  securityWrapper = sourceProg: pkgs.writers.writeBashBin "security-wrapper" ''
    exec ${sourceProg} "$@"
  '';

  mkWrapper =
    { program
    , source
    , owner
    , group
    , permissions
    , setuid
    , setgid
    , codesign
    , ...
    }:
    let
      codesigned = if codesign
        then ''
          # codesign ${source} to "$wrapperDir/${program}" INSTEAD OF the next line
          cp ${securityWrapper source}/bin/security-wrapper "$wrapperDir/${program}"
        ''
        else ''
          cp ${securityWrapper source}/bin/security-wrapper "$wrapperDir/${program}"
        '';
    in
    ''
      ${codesigned}

      # Prevent races
      chmod 0000 "$wrapperDir/${program}"
      chown ${owner}:${group} "$wrapperDir/${program}"

      chmod "u${if setuid then "+" else "-"}s,g${if setgid then "+" else "-"}s,${permissions}" "$wrapperDir/${program}"
    '';
in
{
  # probably not necessary since these options never existed in nix-darwin?
  imports = [
    (lib.mkRemovedOptionModule [ "security" "setuidOwners" ] "Use security.wrappers instead")
    (lib.mkRemovedOptionModule [ "security" "setuidPrograms" ] "Use security.wrappers instead")
  ];

  ###### interface
  options.security = {
    wrappers = lib.mkOption {
      type = lib.types.attrsOf wrapperType;
      default = {};
      example = lib.literalExpression
        ''
        {
          # a setuid root program
          doas =
          { setuid = true;
            owner = "root";
            group = "root";
            source = "''${pkgs.doas}/bin/doas";
          };


          # a setgid program
          locate =
          { setgid = true;
            owner = "root";
            group = "mlocate";
            source = "''${pkgs.locate}/bin/locate";
          };


          # a program with the CAP_NET_RAW capability
          ping =
          { owner = "root";
            group = "root";
            capabilities = "cap_net_raw+ep";
            source = "''${pkgs.iputils.out}/bin/ping";
          };
        }
      '';
      description = lib.mdDoc ''
        This option effectively allows adding setuid/setgid bits, capabilities,
        changing file ownership and permissions of a program without directly
        modifying it. This works by creating a wrapper program under the
        {option}`security.wrapperDir` directory, which is then added to
        the shell `PATH`.
      '';
    };
    wrapperDir = lib.mkOption {
      type = lib.types.path;
      default = "/run/wrappers/bin";
      internal = true;
      description = lib.mdDoc ''
        This option defines the path to the wrapper programs. It
        should not be overridden.
      '';
    };
    codesignIdentity = lib.mkOption {
      type = lib.types.str;
      default = "-";
      description = lib.mdDoc "Identity to use for codesigning.";
    };
  };

  ###### implementation
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

      ${builtins.concatStringsSep "\n" mkWrappedPrograms}

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
