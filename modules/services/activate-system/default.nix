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
        # Make this configuration the current configuration.
        # The readlink is there to ensure that when $systemConfig = /system
        # (which is a symlink to the store), ${config.environment.currentSystemPath} is still
        # used as a garbage collection root.
        ln -sfn $(cat ${config.system.profile}/systemConfig) ${config.environment.currentSystemPath}

        # Prevent the current configuration from being garbage-collected.
        ln -sfn ${config.environment.currentSystemPath} /nix/var/nix/gcroots/current-system

        ${config.system.activationScripts.keyboard.text}
        ${config.system.activationScripts.nix.text}
      '';
      serviceConfig.RunAtLoad = true;
      serviceConfig.KeepAlive.SuccessfulExit = false;
    };

  };
}
