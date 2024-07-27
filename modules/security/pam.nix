{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.security.pam;

  # Implementation Notes
  #
  # Uses `environment.etc` to create the `/etc/pam.d/sudo_local` file that will be used
  # to manage all things pam related for nix-darwin. An activation script will run to check
  # for the existance of the line `auth       include        sudo_local`. This is included
  # in macOS Sonoma and later. If the line is not there already then `sed` will add it.
  # In those cases, the line will include the name of the option root (`security.pam`),
  # to make it easier to identify the line that should be deleted when the option is disabled.
  mkIncludeSudoLocalScript = isEnabled:
  let
    file = "/etc/pam.d/sudo";
    option = "security.pam";
    deprecatedOption = "security.pam.enableSudoTouchIdAuth";
    sed = "${pkgs.gnused}/bin/sed";
  in ''
    ${if isEnabled then ''
      # NOTE: this can be removed at some point when support for older versions are dropped
      # Always clear out older implementation if it exists
      if grep '${deprecatedOption}' ${file} > /dev/null; then
        ${sed} -i '/${option}/d' ${file}
      fi
      # Check if include line is needed (macOS < 14)
      if ! grep 'sudo_local' ${file} > /dev/null; then
        ${sed} -i '2iauth       include        sudo_local # nix-darwin: ${option}' ${file}
      fi
    '' else ''
      # Remove include line if we added it
      if grep '${option}' ${file} > /dev/null; then
        ${sed} -i '/${option}/d' ${file}
      fi
    ''}
  '';
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
  in
  {
    environment.etc."pam.d/sudo_local" = {
      enable = isPamEnabled;
      text = lib.strings.concatStringsSep "\n" [
        (lib.optionalString cfg.enablePamReattach "auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so")
        (lib.optionalString cfg.enableSudoTouchIdAuth "auth       sufficient     pam_tid.so")
      ];
    };
    system.activationScripts.pam.text = ''
      # PAM settings
      echo >&2 "setting up pam..."
      ${mkIncludeSudoLocalScript isPamEnabled}
    '';
  };
}
