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
  mkSudoTouchIdAuthScript = cfg:
    let
      disableTmuxTouchIdAuth = ''
        # Disable tmux Touch ID authentication, if added by nix-darwin
        if grep '${optionTmux}' ${file} > /dev/null; then
          ${sed} -i '/${optionTmux}/d' ${file}
        fi
      '';
      file = cfg.sudoFile;
      optionSudo = "security.pam.enableSudoTouchIdAuth";
      optionTmux = "security.pam.enableTmuxTouchIdAuth";
      sed = "${pkgs.gnused}/bin/sed";
    in
    ''
      ${if cfg.enableSudoTouchIdAuth then ''
        # Enable sudo Touch ID authentication, if not already enabled
        if ! grep 'pam_tid.so' ${file} > /dev/null; then
          ${sed} -i '2i\
        auth       sufficient     pam_tid.so # nix-darwin: ${optionSudo}
          ' ${file}
        fi
        ${if cfg.enableTmuxTouchIdSupport then ''
        # Enable tmux Touch ID authentication, if not already enabled
        if ! grep 'pam_reattach.so' ${file} > /dev/null; then
          ${sed} -i '2i\
        auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so # nix-darwin: ${optionTmux}
          ' ${file}
        fi
        '' else disableTmuxTouchIdAuth
        }
      '' else ''
        ${disableTmuxTouchIdAuth}
        # Disable sudo Touch ID authentication, if added by nix-darwin
        if grep '${optionSudo}' ${file} > /dev/null; then
          ${sed} -i '/${optionSudo}/d' ${file}
        fi
      ''}
    '';
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
      enableTmuxTouchIdSupport = mkEnableOption ''
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
      (pkgs.writeText "pam.patch" ''
        --- a${cfg.sudoFile}
        +++ b${cfg.sudoFile}
        @@ -1,4 +1,6 @@
         # sudo: auth account password session
        +auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so
        +auth       sufficient     pam_tid.so
         auth       sufficient     pam_smartcard.so
         auth       required       pam_opendirectory.so
         account    required       pam_permit.s
      '')
    ];
    system.activationScripts.pam.text = ''
      echo "Hello"
    '';
  };
}
