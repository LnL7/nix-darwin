{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.services.activate-system;

  activateScript = pkgs.writeScript "activate-system" ''
    #! ${pkgs.stdenv.shell}

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

  config = {

    launchd.daemons.activate-system = mkIf cfg.enable {
      serviceConfig.Program = "${activateScript}";
      serviceConfig.RunAtLoad = true;
    };

  };
}
