{ config, lib, pkgs, ... }:

let
  cfg = config.security.pam;
in
{
  options = {
    security.pam = {
      enable = lib.mkEnableOption "managing PAM with nix-darwin" // {
        default = true;
        example = false;
      };

      enableSudoTouchIdAuth = lib.mkEnableOption "" // {
        description = ''
          Whether to enable Touch ID with sudo.

          This will also allow your Apple Watch to be used for sudo. If this doesn't work,
          you can go into `System Settings > Touch ID & Password` and toggle the switch for
          your Apple Watch.
        '';
      };

      enableSudoPamReattach = lib.mkEnableOption "" // {
        description = ''
          Whether to enable reattaching a program to the user's bootstrap session.

          This fixes Touch ID for sudo not working inside tmux and screen.

          This allows programs like tmux and screen that run in the background to
          survive across user sessions to work with PAM services that are tied to the
          bootstrap session.
        '';
        default = cfg.enableSudoTouchIdAuth;
        example = false;
      };
    };
  };

  config = {
    environment.etc."pam.d/sudo_local" = {
      inherit (cfg) enable;
      text = lib.concatLines (
        (lib.optional cfg.enableSudoPamReattach "auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so")
        ++ (lib.optional cfg.enableSudoTouchIdAuth "auth       sufficient     pam_tid.so")
      );
    };

    system.activationScripts.pam.text =
    let
      file = "/etc/pam.d/sudo";
      marker = "security.pam.sudo_local";
      deprecatedOption = "security.pam.enableSudoTouchIdAuth";
      sed = lib.getExe pkgs.gnused;
    in
    ''
      # PAM settings
      echo >&2 "setting up pam..."

      # REMOVEME when macOS 13 no longer supported as macOS automatically
      # nukes this file on system upgrade
      # Always clear out older implementation if it is present
      if grep '${deprecatedOption}' ${file} > /dev/null; then
        ${sed} -i '/${deprecatedOption}/d' ${file}
      fi

      ${if cfg.enable then ''
        # REMOVEME when macOS 13 no longer supported
        # `sudo_local` is automatically included after macOS 14
        if ! grep 'sudo_local' ${file} > /dev/null; then
          ${sed} -i '2iauth       include        sudo_local # nix-darwin: ${marker}' ${file}
        fi
      '' else ''
        # Remove include line if we added it
        if grep '${marker}' ${file} > /dev/null; then
          ${sed} -i '/${marker}/d' ${file}
        fi
      ''}
    '';
  };
}
