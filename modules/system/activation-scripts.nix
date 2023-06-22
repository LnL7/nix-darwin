{ config, lib, pkgs, ... }:

with lib;

let

  inherit (pkgs) stdenv;

  cfg = config.system;

  addAttributeName = mapAttrs (a: v: v // optionalAttrs (v.text != "") {
    text = ''
      #### Activation script snippet ${a}:
      _localstatus=0
      ${v.text}

      if (( _localstatus > 0 )); then
        printf "Activation script snippet '%s' failed (%s)\n" "${a}" "$_localstatus"
      fi
    '';
  });

  path = with pkgs; map getBin
    [ gnugrep
      coreutils
    ];

  massageOrder = set: let
    names = attrNames (removeAttrs set [ "postActivation" ]);
    in mapAttrs (k: v: v // {
      deps =
        v.deps ++
        (if k == "postActivation" then names
         else optional (k != "preActivation" && set ? preActivation) "preActivation"
        );
    } ) set;

  activationScriptBody = set: let
    set' = mapAttrs (_: v: if isString v then (noDepEntry v) else v) set;
    withHeadlines = addAttributeName (massageOrder set');
  in
    textClosureMap id (withHeadlines) (attrNames withHeadlines);

  activationScript = set: system:
    ''
      #!${pkgs.runtimeShell}

      systemConfig='@out@'

      export PATH=/empty
      for i in ${toString path}; do
          PATH=$PATH:$i/bin:$i/sbin
      done

      PATH=$PATH:@out@/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin

      _status=0
      trap "_status=1 _localstatus=\$?" ERR

      # Ensure a consistent umask.
      umask 0022
    '' + optionalString (system) ''
      # Ensure /run exists.
      if [ ! -e /run ]; then
        ln -sfn private/var/run /run
      fi
    '' + ''
      ${activationScriptBody set}
    '' + optionalString (system) ''
      # Make this configuration the current configuration.
      # The readlink is there to ensure that when $systemConfig = /system
      # (which is a symlink to the store), /run/current-system is still
      # used as a garbage collection root.
      ln -sfn "$(readlink -f "$systemConfig")" /run/current-system

      # Prevent the current configuration from being garbage-collected.
      mkdir -p /nix/var/nix/gcroots
      ln -sfn /run/current-system /nix/var/nix/gcroots/current-system
    '' + ''
      exit $_status
    '';

  startupScript = set: let
    set' = filterAttrs (_: v: isString v || (!v.onlyOnRebuild)) set;
    in ''
      systemConfig=$(cat ${config.system.profile}/systemConfig)

      export PATH=/empty
      for i in ${toString path}; do
          PATH=$PATH:$i/bin:$i/sbin
      done

      PATH=$PATH:$systemConfig/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin

      _status=0
      trap "_status=1 _localstatus=\$?" ERR

      # Ensure a consistent umask.
      umask 0022

      # Make this configuration the current configuration.
      # The readlink is there to ensure that when $systemConfig = /system
      # (which is a symlink to the store), /run/current-system is still
      # used as a garbage collection root.
      ln -sfn $(cat ${config.system.profile}/systemConfig) /run/current-system

      # Prevent the current configuration from being garbage-collected.
      ln -sfn /run/current-system /nix/var/nix/gcroots/current-system

      ${activationScriptBody set'}

      exit $_status
    '';

  scriptType = withOnlyOnRebuild:
    let scriptOptions =
      { deps = mkOption
          { type = types.listOf types.str;
            default = [ ];
            description = "List of dependencies. The script will run after these.";
          };
        text = mkOption
          { type = types.lines;
            default = "";
            description = "The content of the script.";
          };
      } // optionalAttrs withOnlyOnRebuild {
        onlyOnRebuild = mkOption
          { type = types.bool;
            default = false;
            description = ''
              Whether this activation script should only be run as part of
              <command>darwin-rebuild</command>. By default, activation scripts
              are run at activation time and on every boot.
            '';
          };
      };
    in with types; either str (submodule { options = scriptOptions; });


  script = import ../lib/write-text.nix {
    inherit lib;
    mkTextDerivation = name: text: pkgs.writeScript "activate-${name}" text;
  };

in

{
  options = {

    system.activationScripts = mkOption {
      type = types.attrsOf (scriptType true);
      default = {};
      description = ''
        A set of shell script fragments that are executed when a nix-darwin
        system configuration is activated.  Examples are updating
        /etc, creating accounts, and so on.  Since these are executed
        every time you boot the system or run
        <command>darwin-rebuild</command>, it's important that they are
        idempotent and fast.
      '';
      apply = set: let
        set' = removeAttrs set [
          # Skip over renamed activation scripts
          "extraUserActivation"
          "preUserActivation"
          "postUserActivation"
        ];
        in set // {
          script = activationScript set' true;
          startupScript = startupScript set';
        };
    };

    system.userActivationScripts = mkOption {
      default = {};

      example = literalExpression ''
        { plasmaSetup = {
            text = '''
              ''${pkgs.libsForQt5.kservice}/bin/kbuildsycoca5"
            ''';
            deps = [];
          };
        }
      '';

      description = ''
        A set of shell script fragments that are executed by a launchd launch
        agent when a nix-darwin system configuration is activated. Examples are
        rebuilding the .desktop file cache for showing applications in the menu.
        Since these are executed every time you run
        <command>darwin-rebuild</command>, it's important that they are
        idempotent and fast.
      '';

      type = with types; attrsOf (scriptType false);

      apply = set: set // {
        script = activationScript set false;
      };
    };
  };

  config = {
    # Extra activation scripts, that can be customized by users
    # don't use this unless you know what you are doing.
    # It's better to define new named activation scripts with lib.stringAfter
    # specifying the exact ordering constraint.
    system.activationScripts.extraActivation.text = mkDefault "";
    system.activationScripts.preActivation.text = mkDefault "";
    system.activationScripts.postActivation.text = mkDefault "";

    # Preserve existing behavior
    system.activationScripts.extraActivation.onlyOnRebuild = true;
    system.activationScripts.preActivation.onlyOnRebuild = true;
    system.activationScripts.postActivation.onlyOnRebuild = true;

    # Support legacy *UserActivation keys.
    system.activationScripts.extraUserActivation.text = mkDefault "";
    system.activationScripts.preUserActivation.text = mkDefault "";
    system.activationScripts.postUserActivation.text = mkDefault "";
    system.userActivationScripts.extraActivation = mkDefault config.system.activationScripts.extraUserActivation.text;
    system.userActivationScripts.preActivation.text = mkDefault config.system.activationScripts.preUserActivation.text;
    system.userActivationScripts.postActivation = mkDefault config.system.activationScripts.postUserActivation.text;
    # Manually generate warnings because mkRenamedOptionModule can't be used with attrset keys.
    warnings = map (name:
      mkIf (config.system.activationScripts.${name + "UserActivation"}.text != "") "Obsolete option `system.activationScripts.${name}UserActivation` is used. It was renamed to `system.userActivationScripts.${name}Activation`."
    ) [ "extra" "pre" "post" ];
  };
}
