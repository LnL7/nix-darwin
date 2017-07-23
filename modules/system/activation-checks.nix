{ config, lib, pkgs, ... }:

with lib;

let
  buildUsers = optionalString config.services.nix-daemon.enable ''
    buildUser=$(dscl . -read /Groups/nixbld GroupMembership 2>&1 | awk '/^GroupMembership: / {print $2}')
    if [ -z $buildUser ]; then
        echo "Using the nix-daemon requires build users, aborting activation" >&2
        exit 2
    fi
  '';
in

{
  options = {
  };

  config = {

    system.activationScripts.checks.text = ''
      set +e
      ${buildUsers}
      set -e
    '';

  };
}
