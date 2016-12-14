{ config, lib, pkgs, ... }:

with lib;

let

  inherit (pkgs) stdenvNoCC;

  cfg = config.system;

in

{
  options = {

    system.build = mkOption {
      internal = true;
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

    system.profile = mkOption {
      type = types.path;
      default = "/nix/var/nix/profiles/system";
      description = ''
        Profile to use for the system.
      '';
    };

    system.nixdarwinLabel = mkOption {
      type = types.str;
      default = "16.09";
    };

  };

  config = {

    system.build.toplevel = stdenvNoCC.mkDerivation {
      name = "nixdarwin-system-${cfg.nixdarwinLabel}";
      preferLocalBuild = true;

      activationScript = cfg.activationScripts.script.text;
      activationUserScript = cfg.activationScripts.userScript.text;
      inherit (cfg) nixdarwinLabel;

      buildCommand = ''
        mkdir $out

        systemConfig=$out

        ln -s ${cfg.build.etc}/etc $out/etc
        ln -s ${cfg.path} $out/sw

        mkdir -p $out/Library
        ln -s ${cfg.build.launchd}/Library/LaunchDaemons $out/Library/LaunchDaemons

        echo "$activationScript" > $out/activate
        substituteInPlace $out/activate --subst-var out
        chmod u+x $out/activate
        unset activationScript

        echo "$activationUserScript" > $out/activate-user
        substituteInPlace $out/activate-user --subst-var out
        chmod u+x $out/activate-user
        unset activationUserScript

        echo -n "$systemConfig" > $out/systemConfig

        echo -n "$nixdarwinLabel" > $out/nixdarwin-version
        echo -n "$system" > $out/system
      '';
    };

  };
}
