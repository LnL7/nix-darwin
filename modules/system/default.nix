{ config, lib, pkgs, ... }:

with lib;

let

  inherit (pkgs) stdenvNoCC;

  cfg = config.system;

  failedAssertions = map (x: x.message) (filter (x: !x.assertion) config.assertions);

  throwAssertions = res: if (failedAssertions != []) then throw "\nFailed assertions:\n${concatStringsSep "\n" (map (x: "- ${x}") failedAssertions)}" else res;
  showWarnings = res: fold (w: x: builtins.trace "[1;31mwarning: ${w}[0m" x) res config.warnings;

in

{
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

    system.kernel.extraModulePackages = mkOption {
      type = types.listOf types.package;
      default = [];
      description = ''
        The packages which provide loadable kexts.
      '';
    };

    system.kernel.extraModulePackagesPath = mkOption {
      internal = true;
      type = types.package;
      description = ''
        The packages which provide loadable kexts.
      '';
    };

    system.profile = mkOption {
      type = types.path;
      default = "/nix/var/nix/profiles/system";
      description = ''
        Profile to use for the system.
      '';
    };

    assertions = mkOption {
      type = types.listOf types.unspecified;
      internal = true;
      default = [];
      example = [ { assertion = false; message = "you can't enable this for that reason"; } ];
      description = ''
        This option allows modules to express conditions that must
        hold for the evaluation of the system configuration to
        succeed, along with associated error messages for the user.
      '';
    };

    warnings = mkOption {
      internal = true;
      default = [];
      type = types.listOf types.str;
      example = [ "The `foo' service is deprecated and will go away soon!" ];
      description = ''
        This option allows modules to show warnings to users during
        the evaluation of the system configuration.
      '';
    };

  };

  config = {
    environment.systemPackages = cfg.kernel.extraModulePackages;
    system.kernel.extraModulePackagesPath = pkgs.buildEnv {
      name = "system-kexts";
      paths = cfg.kernel.extraModulePackages;
      pathsToLink = "/Library/Extensions";
    };

    system.activationScripts.kexts.text = ''
      for f in $(ls "${cfg.kernel.extraModulePackagesPath}/Library/Extensions/" 2> /dev/null); do
        echo "loading kext [$f]:"
        kextutil -v 1 $(readlink "${cfg.kernel.extraModulePackagesPath}/Library/Extensions/$f") 2>&1 >/dev/null | sed "s/^/> /"
      done

      for f in $(ls /run/current-system/Library/Extensions 2> /dev/null); do
        if test ! -e "${cfg.kernel.extraModulePackagesPath}/Library/Extensions/$f"; then
          echo "unloading kext [$f]" >&2
          kextunload -v 1 "/run/current-system/Library/Extensions/$f" || true
        fi
      done
    '';

    launchd.daemons.load-kexts = {
      script = ''
        for f in /run/current-system/Library/Extensions/* do
          echo "loading kext [$f]:"
          kextutil -v 1 $(readlink "${cfg.kernel.extraModulePackagesPath}/Library/Extensions/$f") 2>&1 >/dev/null | sed "s/^/> /"
        done
      '';
      KeepAlive = false;
    }

    system.build.toplevel = throwAssertions (showWarnings (stdenvNoCC.mkDerivation {
      name = "darwin-system-${cfg.darwinLabel}";
      preferLocalBuild = true;

      activationScript = cfg.activationScripts.script.text;
      activationUserScript = cfg.activationScripts.userScript.text;
      inherit (cfg) darwinLabel;

      buildCommand = ''
        mkdir $out

        systemConfig=$out

        mkdir -p $out/darwin
        cp -f ${../../CHANGELOG} $out/darwin-changes

        ln -s ${cfg.build.etc}/etc $out/etc
        ln -s ${cfg.path} $out/sw

        mkdir -p $out/Library
        ln -s ${cfg.build.applications}/Applications $out/Applications
        ln -s ${cfg.build.launchd}/Library/LaunchAgents $out/Library/LaunchAgents
        ln -s ${cfg.build.launchd}/Library/LaunchDaemons $out/Library/LaunchDaemons
        # Kexts
        ln -s "${cfg.kernel.extraModulePackagesPath}/Library/Extensions" "$out/Library/Extensions"

        mkdir -p $out/user/Library
        ln -s ${cfg.build.launchd}/user/Library/LaunchAgents $out/user/Library/LaunchAgents

        echo "$activationScript" > $out/activate
        substituteInPlace $out/activate --subst-var out
        chmod u+x $out/activate
        unset activationScript

        echo "$activationUserScript" > $out/activate-user
        substituteInPlace $out/activate-user --subst-var out
        chmod u+x $out/activate-user
        unset activationUserScript

        echo -n "$systemConfig" > $out/systemConfig

        echo -n "$darwinLabel" > $out/darwin-version
        echo -n "$system" > $out/system
      '';
    }));

  };
}
