{ config, lib, pkgs, ... }:

with lib;

let

  inherit (pkgs) stdenv;

  cfg = config.system;

  script = import ../lib/write-text.nix {
    inherit lib;
    mkTextDerivation = name: text: pkgs.writeScript "activate-${name}" text;
  };

in

{
  options = {

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
      #! ${stdenv.shell}
      set -e
      set -o pipefail
      export PATH="${pkgs.gnugrep}/bin:${pkgs.coreutils}/bin:@out@/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin"

      systemConfig=@out@

      _status=0
      trap "_status=1" ERR

      # Ensure a consistent umask.
      umask 0022

      ${cfg.activationScripts.preActivation.text}

      ${cfg.activationScripts.extraActivation.text}
      ${cfg.activationScripts.groups.text}
      ${cfg.activationScripts.users.text}
      ${cfg.activationScripts.nix.text}
      ${cfg.activationScripts.applications.text}
      ${cfg.activationScripts.etc.text}
      ${cfg.activationScripts.defaults.text}
      ${cfg.activationScripts.launchd.text}
      ${cfg.activationScripts.nix-daemon.text}
      ${cfg.activationScripts.time.text}
      ${cfg.activationScripts.networking.text}
      ${cfg.activationScripts.keyboard.text}
      ${cfg.activationScripts.fonts.text}

      ${cfg.activationScripts.postActivation.text}

      # Ensure /run exists.
      if [ ! -e /run ]; then
        ln -sfn private/var/run /run
      fi

      # Make this configuration the current configuration.
      # The readlink is there to ensure that when $systemConfig = /system
      # (which is a symlink to the store), /run/current-system is still
      # used as a garbage collection root.
      ln -sfn "$(readlink -f "$systemConfig")" /run/current-system

      # Prevent the current configuration from being garbage-collected.
      ln -sfn /run/current-system /nix/var/nix/gcroots/current-system

      exit $_status
    '';

    system.activationScripts.userScript.text = ''
      #! ${stdenv.shell}
      set -e
      set -o pipefail
      export PATH="${pkgs.gnugrep}/bin:${pkgs.coreutils}/bin:@out@/sw/bin:/usr/bin:/bin"

      systemConfig=@out@

      _status=0
      trap "_status=1" ERR

      # Ensure a consistent umask.
      umask 0022

      ${cfg.activationScripts.preUserActivation.text}

      ${cfg.activationScripts.checks.text}
      ${cfg.activationScripts.extraUserActivation.text}
      ${cfg.activationScripts.userDefaults.text}
      ${cfg.activationScripts.userLaunchd.text}

      ${cfg.activationScripts.postUserActivation.text}

      exit $_status
    '';

    # Extra activation scripts, that can be customized by users
    # don't use this unless you know what you are doing.
    system.activationScripts.extraActivation.text = mkDefault "";
    system.activationScripts.preActivation.text = mkDefault "";
    system.activationScripts.postActivation.text = mkDefault "";
    system.activationScripts.extraUserActivation.text = mkDefault "";
    system.activationScripts.preUserActivation.text = mkDefault "";
    system.activationScripts.postUserActivation.text = mkDefault "";

  };
}
