{ config, lib, pkgs, ... }:

with lib;

let
  darwinChanges = ''
    if test -e /run/current-system/darwin-changes; then
      darwinChanges=$(grep -v -f /run/current-system/darwin-changes $systemConfig/darwin-changes 2> /dev/null)
      if test -n "$darwinChanges"; then
        echo >&2
        echo "[1;1mCHANGELOG[0m" >&2
        echo >&2
        echo "$darwinChanges" >&2
        echo >&2
      fi
    fi
  '';

  buildUsers = optionalString config.services.nix-daemon.enable ''
    buildUser=$(dscl . -read /Groups/nixbld GroupMembership 2>&1 | awk '/^GroupMembership: / {print $2}')
    if [ -z $buildUser ]; then
        echo "[1;31merror: Using the nix-daemon requires build users, aborting activation[0m" >&2
        echo "Create the build users or disable the daemon:" >&2
        echo "$ ./bootstrap -u" >&2
        echo >&2
        echo "or set" >&2
        echo >&2
        echo "    services.nix-daemon.enable = false;" >&2
        echo >&2
        exit 2
    fi
  '';

  nixPath = ''
    darwinConfig=$(NIX_PATH=${concatStringsSep ":" config.nix.nixPath} nix-instantiate --eval -E '<darwin-config>')
    if ! test -e "$darwinConfig"; then
        echo "[1;31merror: Changed <darwin-config> but target does not exist, aborting activation[0m" >&2
        echo "Move you configuration.nix or set NIX_PATH:" >&2
        echo >&2
        echo "    nix.nixPath = [ \"darwin-config=$(nix-instantiate --eval -E '<darwin-config>')\" ];" >&2
        echo >&2
        exit 2
    fi

    darwinPath=$(NIX_PATH=${concatStringsSep ":" config.nix.nixPath} nix-instantiate --eval -E '<darwin>')
    if ! test -e "$darwinPath"; then
        echo "[1;31merror: Changed <darwin> but target does not exist, aborting activation[0m" >&2
        echo "Add the darwin repo as a channel or set NIX_PATH:" >&2
        echo "$ sudo nix-channel --add https://github.com/LnL7/nix-darwin/archive/master.tar.gz darwin" >&2
        echo "$ sudo nix-channel --update" >&2
        echo >&2
        echo "or set" >&2
        echo >&2
        echo "    nix.nixPath = [ \"darwin=$(nix-instantiate --eval -E '<darwin>')\" ];" >&2
        echo >&2
        exit 2
    fi

    nixpkgsPath=$(NIX_PATH=${concatStringsSep ":" config.nix.nixPath} nix-instantiate --eval -E '<nixpkgs>')
    if ! test -e "$nixpkgsPath"; then
        echo "[1;31merror: Changed <nixpkgs> but target does not exist, aborting activation[0m" >&2
        echo "Add a nixpkgs channel or set NIX_PATH:" >&2
        echo "$ sudo nix-channel --add http://nixos.org/channels/nixpkgs-unstable nixpkgs" >&2
        echo "$ sudo nix-channel --update" >&2
        echo >&2
        echo "or set" >&2
        echo >&2
        echo "    nix.nixPath = [ \"nixpkgs=$(nix-instantiate --eval -E '<darwin>')\" ];" >&2
        echo >&2
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

      ${darwinChanges}
      ${buildUsers}
      ${nixPath}

      if test ''${checkActivation:-0} -eq 1; then
        echo "ok" >&2
        exit 0
      fi

      set -e
    '';

  };
}
