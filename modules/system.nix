{ config, lib, pkgs, ... }:

with lib;

let

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

    system.nixdarwinLabel = mkOption {
      type = types.str;
      default = "16.09";
    };

  };

  config = {

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
