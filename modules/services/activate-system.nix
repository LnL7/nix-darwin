{ config, lib, pkgs, ... }:

with lib;

let

  inherit (pkgs) stdenv;

  cfg = config.services.activate-system;

  activateScript = pkgs.writeScript "activate-system" ''
    #! ${stdenv.shell}

    # Make this configuration the current configuration.
    # The readlink is there to ensure that when $systemConfig = /system
    # (which is a symlink to the store), /run/current-system is still
    # used as a garbage collection root.
    ln -sfn $(cat ${config.system.profile}/systemConfig) /run/current-system

    # Prevent the current configuration from being garbage-collected.
    ln -sfn /run/current-system /nix/var/nix/gcroots/current-system
  '';

in

{
  options = {
    services.activate-system = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to activate system at boot time.
        '';
      };

    };
  };

  config = mkIf cfg.enable {

    launchd.daemons.activate-system = {
      serviceConfig.Program = "${activateScript}";
      serviceConfig.KeepAlive.SuccessfulExit = false;
      serviceConfig.RunAtLoad = true;
    };

  };
}
