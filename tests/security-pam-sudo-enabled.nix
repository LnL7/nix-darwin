{ config, pkgs, ... }:

{
  security.pam = {
    enableSudoTouchIdAuth = true;
    enableTmuxTouchIdSupport = false;
    sudoFile = "/tmp/etc/pam.d/sudo";
  };

  test =
    let
      file = config.security.pam.sudoFile;
    in
    ''
      mkdir -p /tmp/etc/pam.d
      cat <<EOF > ${file}
      # sudo: auth account password session
      auth       sufficient     pam_smartcard.so
      auth       required       pam_opendirectory.so
      account    required       pam_permit.so
      password   required       pam_deny.so
      session    required       pam_permit.so
      EOF

      eval ${config.system.activationScripts.pam.text}

      if ! grep 'pam_tid.so' ${file} > /dev/null; then
        echo "pam_tid.so not found inside ${file}"
        exit 1
      fi

      if grep 'pam_reattach.so' ${file} > /dev/null; then
        echo "pam_reattach.so found inside ${file}"
        exit 1
      fi
    '';
}

