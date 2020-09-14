{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.security.pam;
in

{
  options = {
    security.pam.enableSudoTouchIdAuth = mkEnableOption ''
      Enable sudo authentication with Touch ID

      When enabled, this option adds the following line to /etc/pam.d/sudo:

          auth       sufficient     pam_tid.so

      (Note that macOS resets this file when doing a system update. As such, sudo
      authentication with Touch ID won't work after a system update until the nix-darwin
      configuration is reapplied.)
    '';
  };

  config = {
    system.activationScripts.pam.text = ''
      # PAM settings
      echo >&2 "setting up pam..."
      ${if cfg.enableSudoTouchIdAuth then ''
        # Enable sudo Touch ID authentication
        if ! grep pam_tid.so /etc/pam.d/sudo > /dev/null; then
          sed -i.orig '2i\
          auth       sufficient     pam_tid.so
          ' /etc/pam.d/sudo
        fi
      '' else ''
        # Disable sudo Touch ID authentication
        if test -e /etc/pam.d/sudo.orig; then
          mv /etc/pam.d/sudo.orig /etc/pam.d/sudo
        fi
      ''}
    '';
  };
}
