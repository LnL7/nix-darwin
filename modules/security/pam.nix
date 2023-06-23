{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.security.pam;
in

{
  options = {
    security.pam.enableSudoTouchIdAuth = mkEnableOption ''
      Enable sudo authentication with Touch ID

      When enabled, this option changes sudo to use a separate pam
      service, sudo-touchid, which contains the entire "sudo" service's
      authentication methods, plus the line:

          auth       sufficient     pam_tid.so
    '';
  };

  config = lib.mkIf (cfg.enableSudoTouchIdAuth) {
    environment.etc."sudoers.d/000-sudo-touchid" = {
      text = ''
        Defaults pam_service=sudo-touchid
        Defaults pam_login_service=sudo-touchid
      '';
    };
    environment.etc."pam.d/sudo-touchid" = {
      text = ''
        auth       sufficient     pam_tid.so
        auth       sufficient     pam_smartcard.so
        auth       required       pam_opendirectory.so
        account    required       pam_permit.so
        password   required       pam_deny.so
        session    required       pam_permit.so
      '';
    };
  };
}
