{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.system.sudo;
in

{
  options = {
    system.sudo.touchid.enable = mkEnableOption "Enable sudo authentication with Touch ID";
  };

  config = mkIf cfg.touchid.enable { system.patches = [ ./etc-pam.d-sudo.patch ]; };
}
