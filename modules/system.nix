{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.system;

  script =
    { config, name, ... }:
    { options = {
        text = mkOption {
          type = types.nullOr types.lines;
          default = null;
          description = "Text of the file.";
        };
        source = mkOption {
          type = types.path;
          description = "Path of the source file.";
        };

        deps = mkOption {
          type = types.listOf types.str;
          default = [];
        };
      };
      config = {
        source = pkgs.writeScript "activate-${name}" ''
          #! ${pkgs.stdenv.shell}

          #### Activation script snippet ${name}:
          ${config.text}
        '';
      };
    };

in {
  options = {

    system.build = mkOption {
      internal = true;
      type = types.attrsOf types.package;
      default = {};
      description = ''
        Attribute set of derivation used to setup the system.
      '';
    };

    system.path = mkOption {
      internal = true;
      type = types.package;
      description = ''
        The packages you want in the system environment.
      '';
    };

    system.nixdarwinLabel = mkOption {
      type = types.str;
      default = "16.09";
    };

    system.activationScripts = mkOption {
      internal = true;
      type = types.attrsOf (types.submodule script);
      default = {};
      description = ''
        A set of shell script fragments that are executed when a NixOS
        system configuration is activated.  Examples are updating
        /etc, creating accounts, and so on.  Since these are executed
        every time you boot the system or run
        <command>nixos-rebuild</command>, it's important that they are
        idempotent and fast.
      '';
    };

  };

  config = {

    system.activationScripts.script.text = ''
      #! ${pkgs.stdenv.shell}

      systemConfig=@out@

      _status=0
      trap "_status=1" ERR

      # Ensure a consistent umask.
      umask 0022

      # Make this configuration the current configuration.
      # The readlink is there to ensure that when $systemConfig = /system
      # (which is a symlink to the store), /run/current-system is still
      # used as a garbage collection root.
      ln -sfn "$(readlink -f "$systemConfig")" /run/current-system

      # Prevent the current configuration from being garbage-collected.
      ln -sfn /run/current-system /nix/var/nix/gcroots/current-system

      exit $_status
    '';

    system.build.toplevel = pkgs.stdenvNoCC.mkDerivation {
      name = "nixdarwin-system-${cfg.nixdarwinLabel}";
      preferLocalBuild = true;

      activationScript = cfg.activationScripts.script.text;
      inherit (cfg) nixdarwinLabel;

      buildCommand = ''
        mkdir $out

        ln -s ${cfg.build.etc}/etc $out/etc
        ln -s ${cfg.path} $out/sw

        echo "$activationScript" > $out/activate
        substituteInPlace $out/activate --subst-var out
        chmod u+x $out/activate
        unset activationScript

        echo -n "$nixdarwinLabel" > $out/nixdarwin-version
        echo -n "$system" > $out/system
      '';
    };

  };
}
