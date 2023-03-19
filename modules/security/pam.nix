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
        TODO
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
    environment.systemPackages = [
      pkgs.pam-reattach
    ];

    environment.pathsToLink = [
      "/lib/pam"
    ];

    system.patches = [
      (pkgs.writeText "pam.patch" ''
        --- a${cfg.sudoPamFile}
        +++ b${cfg.sudoPamFile}
        @@ -1,4 +1,6 @@
         # sudo: auth account password session
        +auth       optional       /run/current-system/sw/lib/pam/pam_reattach.so
        +auth       sufficient     pam_tid.so
         auth       sufficient     pam_smartcard.so
         auth       required       pam_opendirectory.so
         account    required       pam_permit.so
      '')
    ];
  };
}
