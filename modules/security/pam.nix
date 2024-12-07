{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.security.pam;

  pam_watchid = pkgs.stdenv.mkDerivation rec {
    pname = "pam_watchid";
    version = "2.0";

    src = pkgs.fetchFromGitHub {
      owner = "Logicer16";
      repo = pname;
      rev = "b5fe302";
			hash = "sha256-rZyGySbebKezPvQX3GSahh5Oy4b0H2Ar++fKRZuCuIQ=";
    };

    nativeBuildInputs = [ pkgs.swift pkgs.gnused pkgs.llvmPackages_19.libllvm ];

    buildPhase = ''
      mkdir -p build
      cd build

      # Determine whether the macOS Sequoia SDK or later is available
      # CLT_SDK_MAJOR_VER=$(xcrun --sdk macosx --show-sdk-path | xargs readlink -f | xargs basename | sed 's/MacOSX//' | cut -d. -f1)
      # XCODE_SDK_MAJOR_VER=$(xcrun --sdk macosx --show-sdk-path | xargs basename | sed 's/MacOSX//' | cut -d. -f1)
			XCODE_SDK_MAJOR_VER=$(xcrun --sdk macosx --show-sdk-version | cut -d. -f1)
			SDK_REQUIRED_MAJOR_VER=15

			DEFINES=""
			# if [ $SDK_REQUIRED_MAJOR_VER = "$(word 1, $(sort $(SDK_REQUIRED_MAJOR_VER) $(XCODE_SDK_MAJOR_VER)))" ]; then
			if [ "$SDK_REQUIRED_MAJOR_VER" -le "$XCODE_SDK_MAJOR_VER" ]; then
				DEFINES="-DSEQUOIASDK"
			else 
				DEFINES=""
			fi

      echo "SDK_REQUIRED_MAJOR_VER: $SDK_REQUIRED_MAJOR_VER"
      echo "XCODE_SDK_MAJOR_VER: $XCODE_SDK_MAJOR_VER"
      echo "CLT_SDK_MAJOR_VER: $CLT_SDK_MAJOR_VER"
      echo "Using DEFINES: $DEFINES"

      # swiftc ../watchid-pam-extension.swift $DEFINES -o pam_watchid_x86_64.so -target x86_64-apple-darwin$(uname -r) -emit-library

      swiftc ../watchid-pam-extension.swift $DEFINES -o pam_watchid_arm64.so -target arm64-apple-darwin$(uname -r) -emit-library

      # lipo -create pam_watchid_arm64.so pam_watchid_x86_64.so -output pam_watchid.so
			lipo -create pam_watchid_arm64.so -output pam_watchid.so
    '';

    installPhase = ''
      mkdir -p $out/lib/pam
      cp pam_watchid.so $out/lib/pam/${pname}.so
    '';

    meta = {
      description = "PAM module for WatchId authentication";
      homepage = "https://github.com/Logicer16/pam-watchid";
      license = lib.licenses.unlicense;
      platforms = lib.platforms.darwin;
    };
  };

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
  mkSudoTouchIdAuthScript = isEnabled:
  let
    file   = "/etc/pam.d/sudo";
    option = "security.pam.enableSudoTouchIdAuth";
    sed = "${pkgs.gnused}/bin/sed";
  in ''
    ${if isEnabled then ''
      # Enable sudo Touch ID authentication, if not already enabled
      if ! grep 'pam_tid.so' ${file} > /dev/null; then
        ${sed} -i '2i\
      auth       sufficient     pam_tid.so # nix-darwin: ${option}
        ' ${file}
      fi
    '' else ''
      # Disable sudo Touch ID authentication, if added by nix-darwin
      if grep '${option}' ${file} > /dev/null; then
        ${sed} -i '/${option}/d' ${file}
      fi
    ''}
  '';

	mkSudoWatchIdAuthScript = isEnabled:
    let
      file   = "/etc/pam.d/sudo";
      option = "security.pam.enableSudoWatchIdAuth";
      sed    = "${pkgs.gnused}/bin/sed";
    in ''
      ${if isEnabled then ''
        # Ensure pam-watchid is installed
        mkdir -p /usr/local/lib/pam
        cp ${pam_watchid}/lib/pam/pam_watchid.so /usr/local/lib/pam/

        # Enable sudo WatchId authentication, if not already enabled
        if ! grep 'pam_watchid.so' ${file} > /dev/null; then
          ${sed} -i '2i\
        auth       sufficient     pam_watchid.so # nix-darwin: ${option}
          ' ${file}
        fi
      '' else ''
        # Disable sudo WatchId authentication, if added by nix-darwin
        if grep '${option}' ${file} > /dev/null; then
          ${sed} -i '/${option}/d' ${file}
        fi
      ''}
    '';
in

{
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
    security.pam.enableSudoWatchIdAuth = mkEnableOption "" // {
      description = ''
        Enable sudo authentication with Watch ID.

        When enabled, this option adds the following line to
        {file}`/etc/pam.d/sudo`:

        ```
        auth       sufficient     pam_watchid.so
        ```
      '';
    };
  };

  config = {
    system.activationScripts.pam.text = ''
      # PAM settings
      echo >&2 "setting up pam..."
      ${mkSudoTouchIdAuthScript cfg.enableSudoTouchIdAuth}
			${mkSudoWatchIdAuthScript cfg.enableSudoWatchIdAuth}
    '';
  };
}
