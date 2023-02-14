{ makeTest }:

let
  makePamTest = { settings, assertions }: makeTest ({ config, pkgs, ... }: {
    security.pam = settings // {
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
        chmod 666 ${file}

        eval ${config.system.activationScripts.pam.text}

        ${assertions file}
      '';
  });
in
{
  disabled = makePamTest {
    settings = {
      enableSudoTouchIdAuth = false;
      enableTmuxTouchIdSupport = false;
    };
    assertions = file: ''
      if grep 'pam_tid.so' ${file} > /dev/null; then
        echo "pam_tid.so found inside ${file}"
        exit 1
      fi

      if grep 'pam_reattach.so' ${file} > /dev/null; then
        echo "pam_reattach.so found inside ${file}"
        exit 1
      fi
    '';
  };
  sudo-and-tmux-enabled = makePamTest {
    settings = {
      enableSudoTouchIdAuth = true;
      enableTmuxTouchIdSupport = true;
    };
    assertions = file: ''
      if ! grep 'pam_tid.so' ${file} > /dev/null; then
        echo "pam_tid.so not found inside ${file}"
        exit 1
      fi

      if ! grep 'pam_reattach.so' ${file} > /dev/null; then
        echo "pam_reattach.so not found inside ${file}"
        exit 1
      fi
    '';
  };
  sudo-enabled = makePamTest {
    settings = {
      enableSudoTouchIdAuth = true;
      enableTmuxTouchIdSupport = false;
    };
    assertions = file: ''
      if ! grep 'pam_tid.so' ${file} > /dev/null; then
        echo "pam_tid.so not found inside ${file}"
        exit 1
      fi

      if grep 'pam_reattach.so' ${file} > /dev/null; then
        echo "pam_reattach.so found inside ${file}"
        exit 1
      fi
    '';
  };
  tmux-enabled = makePamTest {
    settings = {
      enableSudoTouchIdAuth = false;
      enableTmuxTouchIdSupport = true;
    };
    assertions = file: ''
      if grep 'pam_tid.so' ${file} > /dev/null; then
        echo "pam_tid.so found inside ${file}"
        exit 1
      fi

      if grep 'pam_reattach.so' ${file} > /dev/null; then
        echo "pam_reattach.so found inside ${file}"
        exit 1
      fi
    '';
  };
}
