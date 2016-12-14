{ config, lib, pkgs, ... }:

with lib;

let

  inherit (pkgs) stdenv;

  cfg = config.system;

  script = import ./write-text.nix {
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
      export PATH=${pkgs.coreutils}/bin:${config.environment.systemPath}:$PATH

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

      ${cfg.activationScripts.etc.text}
      ${cfg.activationScripts.launchd.text}

      exit $_status
    '';

    system.activationScripts.userScript.text = ''
      #! ${stdenv.shell}
      set -e
      set -o pipefail
      export PATH=${pkgs.coreutils}/bin:${config.environment.systemPath}:$PATH

      systemConfig=@out@

      _status=0
      trap "_status=1" ERR

      # Ensure a consistent umask.
      umask 0022

      ${cfg.activationScripts.defaults.text}

      exit $_status
    '';

  };
}
