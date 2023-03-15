{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.security.pam;
in
{
  options = {
    security.pam = {
      enableSudoTouchIdAuth = mkEnableOption ''
        Enable sudo authentication with Touch ID

        When enabled, this option adds the following line to /etc/pam.d/sudo:

            auth       sufficient     pam_tid.so

        (Note that macOS resets this file when doing a system update. As such, sudo
        authentication with Touch ID won't work after a system update until the nix-darwin
        configuration is reapplied.)
      '';
      enablePamReattach = mkEnableOption ''
        Enable sudo authentication with Touch ID inside tmux

        When enabled, this option adds the following line to /etc/pam.d/sudo:

            auth       optional     pam_reattach.so

        (Note that macOS resets this file when doing a system update. As such,
        sudo authentication with Touch ID inside tmux won't work after a system
        update until the nix-darwin configuration is reapplied.)
      '';
      sudoFile = mkOption {
        type = types.path;
        default = "/etc/pam.d/sudo";
        description = ''
          Defines the path to the sudo file inside pam.d directory.
        '';
      };
    };
  };

  config = {
    system.patches = [
      (pkgs.writeText "pam.patch" (
        let
          enablePamReattach = cfg.enableSudoTouchIdAuth && cfg.enablePamReattach;
          newLineCount = 5 + (if enablePamReattach then 1 else 0);
        in
        ''
          --- a${cfg.sudoFile}
          +++ b${cfg.sudoFile}
          @@ -1,4 +1,${builtins.toString newLineCount} @@
           # sudo: auth account password session
        '' + (if enablePamReattach then ''
          +auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so
          +auth       sufficient     pam_tid.so
           auth       sufficient     pam_smartcard.so
           auth       required       pam_opendirectory.so
           account    required       pam_permit.s
        '' else ''
          +auth       sufficient     pam_tid.so
           auth       sufficient     pam_smartcard.so
           auth       required       pam_opendirectory.so
           account    required       pam_permit.s
        '')
      ))
    ];
  };
}
