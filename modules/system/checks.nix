{ config, lib, pkgs, ... }:

with lib;

let
  darwinChanges = ''
    darwinChanges=/dev/null
    if test -e /run/current-system/darwin-changes; then
      darwinChanges=/run/current-system/darwin-changes
    fi

    darwinChanges=$(diff --changed-group-format='%>' --unchanged-group-format= /run/current-system/darwin-changes $systemConfig/darwin-changes 2> /dev/null) || true
    if test -n "$darwinChanges"; then
      echo >&2
      echo "[1;1mCHANGELOG[0m" >&2
      echo >&2
      echo "$darwinChanges" >&2
      echo >&2
    fi
  '';

  runLink = ''
    if ! test -e /run; then
        echo "[1;31merror: Directory /run does not exist, aborting activation[0m" >&2
        echo "Create a symlink to /var/run with:" >&2
        echo >&2
        echo "    sudo ln -s private/var/run /run" >&2
        echo >&2
        exit 2
    fi
  '';

  buildUsers = optionalString config.services.nix-daemon.enable ''
    buildUser=$(dscl . -read /Groups/nixbld GroupMembership 2>&1 | awk '/^GroupMembership: / {print $2}') || true
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

  nixChannels = ''
    channelsLink=$(readlink "$HOME/.nix-defexpr/channels") || true
    case "$channelsLink" in
      *"$USER"*)
        ;;
      "")
        ;;
      *)
        echo "[1;31merror: The ~/.nix-defexpr/channels symlink does not point your users channels, aborting activation[0m" >&2
        echo "Running nix-channel will regenerate it" >&2
        echo >&2
        echo "    rm ~/.nix-defexpr/channels" >&2
        echo "    nix-channel --update" >&2
        echo >&2
        exit 2
        ;;
    esac
  '';

  nixInstaller = ''
    if grep -q 'etc/profile.d/nix-daemon.sh' /etc/profile; then
        echo "[1;31merror: Found nix-daemon.sh reference in /etc/profile, aborting activation[0m" >&2
        echo "This will override options like nix.nixPath because it runs later," >&2
        echo "remove this snippet from /etc/profile:" >&2
        echo >&2
        echo "    # Nix" >&2
        echo "    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then" >&2
        echo "      . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'" >&2
        echo "    fi" >&2
        echo "    # End Nix" >&2
        echo >&2
        exit 2
    fi
  '';

  nixPath = ''
    darwinConfig=$(NIX_PATH=${concatStringsSep ":" config.nix.nixPath} nix-instantiate --eval -E '<darwin-config>' || echo '$HOME/.nixpkgs/darwin-configuration.nix') || true
    if ! test -e "$darwinConfig"; then
        echo "[1;31merror: Changed <darwin-config> but target does not exist, aborting activation[0m" >&2
        echo "Create $darwinConfig or set nix.nixPath:" >&2
        echo >&2
        echo "    nix.nixPath = [ \"darwin-config=$(nix-instantiate --eval -E '<darwin-config>' 2> /dev/null || echo '***')\" ];" >&2
        echo >&2
        exit 2
    fi

    darwinPath=$(NIX_PATH=${concatStringsSep ":" config.nix.nixPath} nix-instantiate --eval -E '<darwin>') || true
    if ! test -e "$darwinPath"; then
        echo "[1;31merror: Changed <darwin> but target does not exist, aborting activation[0m" >&2
        echo "Add the darwin repo as a channel or set nix.nixPath:" >&2
        echo "$ nix-channel --add https://github.com/LnL7/nix-darwin/archive/master.tar.gz darwin" >&2
        echo "$ nix-channel --update" >&2
        echo >&2
        echo "or set" >&2
        echo >&2
        echo "    nix.nixPath = [ \"darwin=$(nix-instantiate --eval -E '<darwin>')\" ];" >&2
        echo >&2
        exit 2
    fi

    nixpkgsPath=$(NIX_PATH=${concatStringsSep ":" config.nix.nixPath} nix-instantiate --eval -E '<nixpkgs>') || true
    if ! test -e "$nixpkgsPath"; then
        echo "[1;31merror: Changed <nixpkgs> but target does not exist, aborting activation[0m" >&2
        echo "Add a nixpkgs channel or set nix.nixPath:" >&2
        echo "$ nix-channel --add http://nixos.org/channels/nixpkgs-unstable nixpkgs" >&2
        echo "$ nix-channel --update" >&2
        echo >&2
        echo "or set" >&2
        echo >&2
        echo "    nix.nixPath = [ \"nixpkgs=$(nix-instantiate --eval -E '<nixpkgs>')\" ];" >&2
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
      ${darwinChanges}
      ${runLink}
      ${buildUsers}
      ${nixChannels}
      ${nixInstaller}
      ${nixPath}

      if test ''${checkActivation:-0} -eq 1; then
        echo "ok" >&2
        exit 0
      fi
    '';

  };
}
