{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.system.checks;

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
        if test -e /etc/synthetic.conf; then
            echo >&2
            echo "$ echo "run\tprivate/var/run" | sudo tee -a /etc/synthetic.conf" >&2
            echo "$ /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -B" >&2
            echo >&2
            echo "The current contents of /etc/synthetic.conf is:" >&2
            echo >&2
            sed 's/^/    /' /etc/synthetic.conf >&2
            echo >&2
        else
            echo >&2
            echo "$ sudo ln -s private/var/run /run" >&2
            echo >&2
        fi
        exit 2
    fi
  '';

  buildUsers = ''
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

  singleUser = ''
    if grep -q 'build-users-group =' /etc/nix/nix.conf; then
        echo "[1;31merror: The daemon is not enabled but this is a multi-user install, aborting activation[0m" >&2
        echo "Enable the nix-daemon service:" >&2
        echo >&2
        echo "    services.nix-daemon.enable = true;" >&2
        echo >&2
        echo "or set" >&2
        echo >&2
        echo "    nix.useDaemon = true;" >&2
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
    darwinConfig=$(NIX_PATH=${concatStringsSep ":" config.nix.nixPath} nix-instantiate --find-file darwin-config) || true
    if ! test -e "$darwinConfig"; then
        echo "[1;31merror: Changed <darwin-config> but target does not exist, aborting activation[0m" >&2
        echo "Create ''${darwinConfig:-~/.nixpkgs/darwin-configuration.nix} or set environment.darwinConfig:" >&2
        echo >&2
        echo "    environment.darwinConfig = \"$(nix-instantiate --find-file darwin-config 2> /dev/null || echo '***')\";" >&2
        echo >&2
        echo "And rebuild using (only required once)" >&2
        echo "$ darwin-rebuild switch -I \"darwin-config=$(nix-instantiate --find-file darwin-config 2> /dev/null || echo '***')\"" >&2
        echo >&2
        echo >&2
        exit 2
    fi

    darwinPath=$(NIX_PATH=${concatStringsSep ":" config.nix.nixPath} nix-instantiate --find-file darwin) || true
    if ! test -e "$darwinPath"; then
        echo "[1;31merror: Changed <darwin> but target does not exist, aborting activation[0m" >&2
        echo "Add the darwin repo as a channel or set nix.nixPath:" >&2
        echo "$ nix-channel --add https://github.com/LnL7/nix-darwin/archive/master.tar.gz darwin" >&2
        echo "$ nix-channel --update" >&2
        echo >&2
        echo "or set" >&2
        echo >&2
        echo "    nix.nixPath = [ \"darwin=$(nix-instantiate --find-file darwin 2> /dev/null || echo '***')\" ];" >&2
        echo >&2
        exit 2
    fi

    nixpkgsPath=$(NIX_PATH=${concatStringsSep ":" config.nix.nixPath} nix-instantiate --find-file nixpkgs) || true
    if ! test -e "$nixpkgsPath"; then
        echo "[1;31merror: Changed <nixpkgs> but target does not exist, aborting activation[0m" >&2
        echo "Add a nixpkgs channel or set nix.nixPath:" >&2
        echo "$ nix-channel --add http://nixos.org/channels/nixpkgs-unstable nixpkgs" >&2
        echo "$ nix-channel --update" >&2
        echo >&2
        echo "or set" >&2
        echo >&2
        echo "    nix.nixPath = [ \"nixpkgs=$(nix-instantiate --find-file nixpkgs 2> /dev/null || echo '***')\" ];" >&2
        echo >&2
        exit 2
    fi
  '';

  nixStore = ''
    if test -w /nix/var/nix/db -a ! -O /nix/store; then
        echo >&2 "[1;31merror: the store is not owned by this user, but /nix/var/nix/db is writable[0m"
        echo >&2 "If you are using the daemon:"
        echo >&2
        echo >&2 "    sudo chown -R /nix/var/nix/db"
        echo >&2
        exit 2
    fi
  '';

  nixGarbageCollector = ''
    if test -O /nix/store; then
        echo "[1;31merror: A single-user install can't run gc as root, aborting activation[0m" >&2
        echo "Configure the garbage collector to run as the current user:" >&2
        echo >&2
        echo "    nix.gc.user = \"$USER\";" >&2
        echo >&2
        exit 2
    fi
  '';
in

{
  options = {
    system.checks.verifyNixPath = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to run the NIX_PATH validation checks.";
    };

    system.checks.text = mkOption {
      internal = true;
      type = types.lines;
      default = "";
    };
  };

  config = {

    system.checks.text = mkMerge [
      darwinChanges
      runLink
      (mkIf config.nix.useDaemon buildUsers)
      (mkIf (!config.nix.useDaemon) singleUser)
      nixStore
      (mkIf (config.nix.gc.automatic && config.nix.gc.user == null) nixGarbageCollector)
      nixChannels
      nixInstaller
      (mkIf cfg.verifyNixPath nixPath)
    ];

    system.activationScripts.checks.text = ''
      ${cfg.text}

      if test ''${checkActivation:-0} -eq 1; then
        echo "ok" >&2
        exit 0
      fi
    '';

  };
}
