{ config, lib, pkgs, ... }:

with lib;

let
  inherit (pkgs) stdenv;

  cfg = config.services.activate-system;
in

{
  options = {
    services.activate-system.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to activate system at boot time.";
    };
  };

  config = mkIf cfg.enable {

    launchd.daemons.activate-system = {
      script = ''
        set -e
        set -o pipefail
        export PATH="${pkgs.gnugrep}/bin:${pkgs.coreutils}/bin:@out@/sw/bin:/usr/bin:/bin:/usr/sbin:/sbin"

        systemConfig=$(cat ${config.system.profile}/systemConfig)

        # Make this configuration the current configuration.
        # The readlink is there to ensure that when $systemConfig = /system
        # (which is a symlink to the store), /run/current-system is still
        # used as a garbage collection root.
        ln -sfn $(cat ${config.system.profile}/systemConfig) /run/current-system

        # Prevent the current configuration from being garbage-collected.
        ln -sfn /run/current-system /nix/var/nix/gcroots/current-system

        ${config.system.activationScripts.etc.text}
        ${config.system.activationScripts.keyboard.text}
      '';
      serviceConfig.RunAtLoad = true;
      serviceConfig.KeepAlive.SuccessfulExit = false;
    };

  };
}
