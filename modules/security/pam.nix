{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.security.pam;
in
{
  options = {
    security.pam = {
      enableSudoTouchIdAuth = mkEnableOption "" // {
        description = ''
          Enable sudo authentication with Touch ID.
          When enabled, this option adds the following line to {file}:
          ```
          auth       sufficient     pam_tid.so
          ```
        '';
      };
      enablePamReattach = mkEnableOption "" // {
        description = ''
          Enable re-attaching a program to the user's bootstrap session.
          This allows programs like tmux and screen that run in the background to
          survive across user sessions to work with PAM services that are tied to the
          bootstrap session.
          When enabled, this option adds the following line to /etc/pam.d/sudo_local:
          ```
          auth       optional       /path/in/nix/store/lib/pam/pam_reattach.so"
          ```
        '';
      };
    };
  };

  config =
  let
    isPamEnabled = (cfg.enableSudoTouchIdAuth || cfg.enablePamReattach);

    # Implementation Notes
    #
    # Uses `environment.etc` to create the `/etc/pam.d/sudo_local` file that will be used
    # to manage all things pam related for nix-darwin. An activation script will run to check
    # for the existance of the line `auth       include        sudo_local`. This is included
    # in macOS Sonoma and later. If the line is not there already then `sed` will add it.
    # In those cases, the line will include the marker (`security.pam.sudo_local`),
    # to make it easier to identify the line that should be deleted when the option is disabled.
    # Upgrading to Sonoma from a previous version should see the `/etc/pam.d/sudo` file
    # replaced with one containing the `auth        include        sudo_local` line, but
    # it will not include the marker because this line's inclusion is now managed by Apple.
  in
  {
    environment.etc."pam.d/sudo_local" = {
      enable = isPamEnabled;
      text = lib.concatLines [
        (lib.mkIf cfg.enablePamReattach "auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so")
        (lib.mkIf cfg.enableSudoTouchIdAuth "auth       sufficient     pam_tid.so")
      ];
    };
    system.activationScripts.pam.text =
    let
      file = "/etc/pam.d/sudo";
      marker = "security.pam";
      deprecatedOption = "security.pam.enableSudoTouchIdAuth";
      sed = "${pkgs.gnused}/bin/sed";
    in
    ''
      # PAM settings
      echo >&2 "setting up pam..."
      ${if isPamEnabled then ''
        # REMOVEME when macOS 13 no longer supported
        # Always clear out older implementation if it exists
        if grep '${deprecatedOption}' ${file} > /dev/null; then
          ${sed} -i '/${deprecatedOption}/d' ${file}
        fi
        # Check if include line is needed (macOS < 14)
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
