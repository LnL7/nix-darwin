{ config, lib, pkgs, ... }:

with lib;

let cfg = config.security.pam;

in {
  options = {
    security.pam.enableSudoTouchIdAuth = mkEnableOption "" // {
      description = ''
        Enable sudo authentication with Touch ID.

        When enabled, this option adds the following line to
        {file}`/etc/pam.d/sudo`:

        ```
        auth       sufficient     pam_tid.so
        ```

        ::: {.note}
        macOS resets this file when doing a system update. As such, sudo
        authentication with Touch ID won't work after a system update
        until the nix-darwin configuration is reapplied.
        :::
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enableSudoTouchIdAuth {
      # This is the example given in `/etc/pam.d/sudo_local.template`.
      # This file is sourced by `/etc/pam.d/sudo`, and will not be overwritten after Darwin upgrades.
      environment.etc."pam.d/sudo_local".text = ''
        auth       sufficient     pam_tid.so
      '';
    })
    # Clean up for old versions of `nix-darwin` that didn't use `/etc/pam.d/sudo_local`.
    (lib.mkIf (!cfg.enableSudoTouchIdAuth) {
      system.activationScripts.pam.text = let
        file = "/etc/pam.d/sudo";
        option = "security.pam.enableSudoTouchIdAuth";
        sed = "${pkgs.gnused}/bin/sed";
      in ''
        # Old versions of `nix-darwin` modified `/etc/pam.d/sudo` with `sed` to
        # control this behavior, but since then MacOS has seen an update that
        # adds a template `sudo_local` file that can be modified by machine administrators.
        # This option will cause Nix to take ownership of the `sudo_local` file.
        # Disable sudo Touch ID authentication, if added by nix-darwin
        if grep '${option}' ${file} > /dev/null; then
          ${sed} -i '/${option}/d' ${file}
        fi
      '';
    })
  ];
}
