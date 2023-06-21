{ config
, lib
, pkgs
, ...
}:
with lib; let
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
        Enable re-attaching a program to the user's bootstrap session.

        This allows programs like tmux and screen that run in the background to
        survive across user sessions to work with PAM services that are tied to the
        bootstrap session.

        When enabled, this option adds the following line to /etc/pam.d/sudo:

            auth       optional       /path/in/nix/store/lib/pam/pam_reattach.so"

        (Note that macOS resets this file when doing a system update. As such, sudo
        authentication with Touch ID won't work after a system update until the nix-darwin
        configuration is reapplied.)
      '';
      sudoPamFile = mkOption {
        type = types.path;
        default = "/etc/pam.d/sudo";
        description = ''
          Defines the path to the sudo file inside pam.d directory.
        '';
      };
    };
  };

  config = {
    environment.pathsToLink = optional cfg.enablePamReattach "/lib/pam";

    system.patches =
      if cfg.enableSudoTouchIdAuth && cfg.enablePamReattach
      then [(pkgs.writeText "pam-reattach-tid.patch" ''
          --- a/etc/pam.d/sudo
          +++ b/etc/pam.d/sudo
          @@ -1,4 +1,6 @@
           # sudo: auth account password session
          +auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so
          +auth       sufficient     pam_tid.so
           auth       sufficient     pam_smartcard.so
           auth       required       pam_opendirectory.so
           account    required       pam_permit.so
        '')
      ]
      else if cfg.enableSudoTouchIdAuth && !cfg.enablePamReattach
      then [(pkgs.writeText "pam-tid.patch" ''
          --- a/etc/pam.d/sudo
          +++ b/etc/pam.d/sudo
          @@ -1,4 +1,5 @@
           # sudo: auth account password session
          +auth       sufficient     pam_tid.so
           auth       sufficient     pam_smartcard.so
           auth       required       pam_opendirectory.so
           account    required       pam_permit.so
        '')
      ]
      else if !cfg.enableSudoTouchIdAuth && cfg.enablePamReattach
      then [(pkgs.writeText "pam-reattach.patch" ''
          --- a/etc/pam.d/sudo
          +++ b/etc/pam.d/sudo
          @@ -1,4 +1,5 @@
           # sudo: auth account password session
          +auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so
           auth       sufficient     pam_smartcard.so
           auth       required       pam_opendirectory.so
           account    required       pam_permit.so
        '')
      ]
      else [ ];
  };
}
