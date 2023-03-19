{ makeTest }:

let
  makePamTest = { settings, assertions }: makeTest ({ config, pkgs, ... }: {
    security.pam = settings // {
      sudoPamFile = pkgs.writeTextFile {
        name = "pam_file";
        text = ''
          # sudo: auth account password session
          auth       sufficient     pam_smartcard.so
          auth       required       pam_opendirectory.so
          account    required       pam_permit.so
          password   required       pam_deny.so
          session    required       pam_permit.so
        '';
        checkPhase = ''
          echo "===================="
          echo $out
          echo "===================="
        '';
      };
    };

    test =
      let
        file = config.security.pam.sudoPamFile;
      in
      ''
        ${assertions file}
      '';
  });
in
{
  foo = makePamTest {
    settings = {
      enableSudoTouchIdAuth = true;
      enablePamReattach = true;
    };
    assertions = file: ''
      exit 1
    '';
  };

  # sudo-and-tmux-enabled = makePamTest {
  #   settings = {
  #     enableSudoTouchIdAuth = true;
  #     enablePamReattach = true;
  #   };
  #   assertions = file: ''
  #     if ! grep 'pam_tid.so' ${file} > /dev/null; then
  #       echo "pam_tid.so not found inside ${file}"
  #       exit 1
  #     fi

  #     if ! grep 'pam_reattach.so' ${file} > /dev/null; then
  #       echo "pam_reattach.so not found inside ${file}"
  #       exit 1
  #     fi
  #   '';
  # };
  # sudo-enabled = makePamTest {
  #   settings = {
  #     enableSudoTouchIdAuth = true;
  #     enablePamReattach = false;
  #   };
  #   assertions = file: ''
  #     if ! grep 'pam_tid.so' ${file} > /dev/null; then
  #       echo "pam_tid.so not found inside ${file}"
  #       exit 1
  #     fi

  #     if grep 'pam_reattach.so' ${file} > /dev/null; then
  #       echo "pam_reattach.so found inside ${file}"
  #       exit 1
  #     fi
  #   '';
  # };
  # tmux-enabled = makePamTest {
  #   settings = {
  #     enableSudoTouchIdAuth = false;
  #     enablePamReattach = true;
  #   };
  #   assertions = file: ''
  #     if grep 'pam_tid.so' ${file} > /dev/null; then
  #       echo "pam_tid.so found inside ${file}"
  #       exit 1
  #     fi

  #     if grep 'pam_reattach.so' ${file} > /dev/null; then
  #       echo "pam_reattach.so found inside ${file}"
  #       exit 1
  #     fi
  #   '';
  # };
}
