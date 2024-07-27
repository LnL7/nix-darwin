{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.security.pam;

  # Implementation Notes
  #
  # We don't use `environment.etc` because this would require that the user manually delete
  # `/etc/pam.d/sudo` which seems unwise given that applying the nix-darwin configuration requires
  # sudo. We also can't use `system.patchs` since it only runs once, and so won't patch in the
  # changes again after OS updates (which remove modifications to this file).
  #
  # As such, we resort to line addition/deletion in place using `sed`. We add a comment to the
  # added line that includes the name of the option, to make it easier to identify the line that
  # should be deleted when the option is disabled.
  template   = "/etc/pam.d/sudo_local.template";
  file   = "/etc/pam.d/sudo_local";
  sed = "${pkgs.gnused}/bin/sed";
  mkSudoLocal = isEnabled:
  ''
    ${if isEnabled then ''
      if [ ! -f ${file} ]; then
        cp ${template} ${file}
      fi
    '' else ''
      if [ -f ${file} ]; then
        rm ${file}
      fi
    ''}
  '';
  mkSudoTouchIdAuthScript = isEnabled:
  let
    option = "security.pam.enableSudoTouchIdAuth";
  in
  ''
    ${if isEnabled then ''
      if ! grep '${option}' ${file} > /dev/null; then
        ${sed} -i 's/#\(auth\s\+sufficient\s\+pam_tid.so\)/\1 # nix-darwin: ${option}/g' ${file}
      fi
    '' else ''
      if grep '${option}' ${file} > /dev/null; then
        ${sed} -i 's/\(.*\)#.*${option}/#\1/g' ${file}
      fi
    ''}
  '';
  mkPamReattachScript = isEnabled:
  let
    option = "security.pam.enablePamReattach";
  in
  # NOTE: needs to check that `pkgs.pam-reattach` is in the line in case the store location updates
  ''
    ${if isEnabled then ''
      if ! grep '${pkgs.pam-reattach}' ${file} > /dev/null; then
        if grep '${option}' ${file} > /dev/null; then
          ${sed} -i '/${option}/d' ${file}
        fi
        ${sed} -i '1iauth optional ${pkgs.pam-reattach}/lib/pam/pam_reattach.so # nix-darwin: ${option}' ${file}
      fi
    '' else ''
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

        When enabled, this option creates {file}
        from {template}:

        ```
        # sudo_local: local config file which survives system update and is included for sudo
        # uncomment following line to enable Touch ID for sudo
        auth       sufficient     pam_tid.so
        ```
      '';
    };
    enablePamReattach = mkEnableOption ''
        Enable re-attaching a program to the user's bootstrap session.
        This allows programs like tmux and screen that run in the background to
        survive across user sessions to work with PAM services that are tied to the
        bootstrap session.
        When enabled, this option adds the following line to /etc/pam.d/sudo_local:
            auth       optional       /path/in/nix/store/lib/pam/pam_reattach.so"
        (Note that macOS resets this file when doing a system update. As such, sudo
        authentication with Touch ID won't work after a system update until the nix-darwin
        configuration is reapplied.)
      '';
    };
  };

  config = {
    system.activationScripts.pam.text = ''
      # PAM settings
      echo >&2 "setting up pam..."
      ${mkSudoLocal (cfg.enableSudoTouchIdAuth || cfg.enablePamReattach)}
      ${mkPamReattachScript cfg.enablePamReattach}
      ${mkSudoTouchIdAuthScript cfg.enableSudoTouchIdAuth}
    '';
  };
}
