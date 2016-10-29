{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.system;

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

    # Used by <nixos/modules/system/etc/etc.nix>
    system.activationScripts = mkOption { internal = true; };

  };

  config = {

    system.activationScripts.script = ''
      #! ${pkgs.stdenv.shell}

      systemConfig=@out@

      # Make this configuration the current configuration.
      # The readlink is there to ensure that when $systemConfig = /system
      # (which is a symlink to the store), /run/current-system is still
      # used as a garbage collection root.
      ln -sfn "$(readlink -f "$systemConfig")" /run/current-system

      # Prevent the current configuration from being garbage-collected.
      ln -sfn /run/current-system /nix/var/nix/gcroots/current-system

    '';

    system.build.toplevel = pkgs.stdenvNoCC.mkDerivation {
      name = "nixdarwin-system-${cfg.nixdarwinLabel}";
      preferLocalBuild = true;

      activationScript = config.system.activationScripts.script;
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
