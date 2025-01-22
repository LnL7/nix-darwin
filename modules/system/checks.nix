{ config, lib, pkgs, ... }:

with lib;

let
  # Similar to lib.escapeShellArg but escapes "s instead of 's, to allow for parameter expansion in shells
  escapeDoubleQuote = arg: ''"${replaceStrings ["\""] ["\"\\\"\""] (toString arg)}"'';

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

  macOSVersion = ''
    IFS=. read -ra osVersion <<<"$(sw_vers --productVersion)"
    if (( osVersion[0] < 11 || (osVersion[0] == 11 && osVersion[1] < 3) )); then
      printf >&2 '\e[1;31merror: macOS version is less than 11.3, aborting activation\e[0m\n'
      printf >&2 'Nixpkgs 25.05 requires macOS Big Sur 11.3 or newer, and 25.11 will\n'
      printf >&2 'require macOS Sonoma 14.\n'
      printf >&2 '\n'
      printf >&2 'For more information on your options going forward, see the 25.05\n'
      printf >&2 'release notes:\n'
      printf >&2 '<https://nixos.org/manual/nixos/unstable/release-notes#sec-release-25.05>\n'
      printf >&2 '\n'
      printf >&2 'Nixpkgs 24.11 and nix-darwin 24.11 continue to support down to macOS\n'
      printf >&2 'Sierra 10.12, and will be supported through June 2025.\n'
      printf >&2 '\n'
      printf >&2 'You can override this check by setting:\n'
      printf >&2 '\n'
      printf >&2 '    system.checks.verifyMacOSVersion = false;\n'
      printf >&2 '\n'
      printf >&2 'However, we are unable to provide support if you do so.\n'
      exit 1
    fi
  '';

  oldBuildUsers = ''
    if dscl . -list /Users | grep -q '^nixbld'; then
        echo "[1;31merror: Detected old style nixbld users, aborting activation[0m" >&2
        echo "These can cause migration problems when upgrading to certain macOS versions" >&2
        echo "You can enable the following option to migrate to new style nixbld users" >&2
        echo >&2
        echo "    nix.configureBuildUsers = true;" >&2
        echo >&2
        echo "or disable this check with" >&2
        echo >&2
        echo "    system.checks.verifyBuildUsers = false;" >&2
        echo >&2
        exit 2
     fi
   '';

  preSequoiaBuildUsers = ''
    ${lib.optionalString config.nix.configureBuildUsers ''
      # Don’t complain when we’re about to migrate old‐style build users…
      if ! dscl . -list /Users | grep -q '^nixbld'; then
    ''}
    firstBuildUserID=$(dscl . -read /Users/_nixbld1 UniqueID | awk '{print $2}')
    if [[ $firstBuildUserID != ${toString (config.ids.uids.nixbld + 1)} ]]; then
        printf >&2 '\e[1;31merror: Build users have unexpected UIDs, aborting activation\e[0m\n'
        printf >&2 'The default Nix build user ID range has been adjusted for\n'
        printf >&2 'compatibility with macOS Sequoia 15. Your _nixbld1 user currently has\n'
        printf >&2 'UID %d rather than the new default of 351.\n' "$firstBuildUserID"
        printf >&2 '\n'
        printf >&2 'You can automatically migrate the users with the following command:\n'
        printf >&2 '\n'
        if [[ -e /nix/receipt.json ]]; then
            if
                ${pkgs.jq}/bin/jq --exit-status \
                'try(.planner.settings | has("enable_flakes"))' \
                /nix/receipt.json \
                >/dev/null
            then
                installerUrl="https://install.lix.systems/lix"
            else
                installerUrl="https://install.determinate.systems/nix"
            fi
            printf >&2 "    curl --proto '=https' --tlsv1.2 -sSf -L %s | sh -s -- repair sequoia --move-existing-users\n" \
                "$installerUrl"
        else
            printf >&2 "    curl --proto '=https' --tlsv1.2 -sSf -L https://github.com/NixOS/nix/raw/master/scripts/sequoia-nixbld-user-migration.sh | bash -\n"
        fi
        printf >&2 '\n'
        printf >&2 'If you have no intention of upgrading to macOS Sequoia 15, or already\n'
        printf >&2 'have a custom UID range that you know is compatible with Sequoia, you\n'
        printf >&2 'can disable this check by setting:\n'
        printf >&2 '\n'
        printf >&2 '    ids.uids.nixbld = %d;\n' "$((firstBuildUserID - 1))"
        printf >&2 '\n'
        exit 2
    fi
    ${lib.optionalString config.nix.configureBuildUsers "fi"}
  '';

  buildUsers = ''
    buildUser=$(dscl . -read /Groups/nixbld GroupMembership 2>&1 | awk '/^GroupMembership: / {print $2}') || true
    if [[ -z "$buildUser" ]]; then
        echo "[1;31merror: Using the nix-daemon requires build users, aborting activation[0m" >&2
        echo "Create the build users or disable the daemon:" >&2
        echo "$ darwin-install" >&2
        echo >&2
        echo "or set (this requires some manual intervention to restore permissions)" >&2
        echo >&2
        echo "    services.nix-daemon.enable = false;" >&2
        echo >&2
        exit 2
    fi
  '';

  buildGroupID = ''
    buildGroupID=$(dscl . -read /Groups/nixbld PrimaryGroupID | awk '{print $2}')
    expectedBuildGroupID=${toString config.ids.gids.nixbld}
    if [[ $buildGroupID != "$expectedBuildGroupID" ]]; then
        printf >&2 '\e[1;31merror: Build user group has mismatching GID, aborting activation\e[0m\n'
        printf >&2 'The default Nix build user group ID was changed from 30000 to 350.\n'
        printf >&2 'You are currently managing Nix build users with nix-darwin, but your\n'
        printf >&2 'nixbld group has GID %d, whereas we expected %d.\n' \
          "$buildGroupID" "$expectedBuildGroupID"
        printf >&2 '\n'
        printf >&2 'Possible causes include setting up a new Nix installation with an\n'
        printf >&2 'existing nix-darwin configuration, setting up a new nix-darwin\n'
        printf >&2 'installation with an existing Nix installation, or manually increasing\n'
        printf >&2 'your `system.stateVersion` setting.\n'
        printf >&2 '\n'
        printf >&2 'You can set the configured group ID to match the actual value:\n'
        printf >&2 '\n'
        printf >&2 '    ids.gids.nixbld = %d;\n' "$buildGroupID"
        printf >&2 '\n'
        printf >&2 'We do not recommend trying to change the group ID with macOS user\n'
        printf >&2 'management tools without a complete uninstallation and reinstallation\n'
        printf >&2 'of Nix.\n'
        exit 2
    fi
  '';

  nixDaemon = if config.nix.useDaemon then ''
    if ! dscl . -read /Groups/nixbld PrimaryGroupID &> /dev/null; then
      printf >&2 '[1;31merror: The daemon should not be enabled for single-user installs, aborting activation[0m\n'
      printf >&2 'Disable the nix-daemon service:\n'
      printf >&2 '\n'
      printf >&2 '    services.nix-daemon.enable = false;\n'
      printf >&2 '\n'
      printf >&2 'and remove `nix.useDaemon` from your configuration if it is present.\n'
      printf >&2 '\n'
      exit 2
    fi
  '' else ''
    if dscl . -read /Groups/nixbld PrimaryGroupID &> /dev/null; then
      printf >&2 '[1;31merror: The daemon should be enabled for multi-user installs, aborting activation[0m\n'
      printf >&2 'Enable the nix-daemon service:\n'
      printf >&2 '\n'
      printf >&2 '    services.nix-daemon.enable = true;\n'
      printf >&2 '\n'
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
    nixPath=${concatMapStringsSep ":" escapeDoubleQuote config.nix.nixPath}:$HOME/.nix-defexpr/channels

    darwinConfig=$(NIX_PATH=$nixPath nix-instantiate --find-file darwin-config) || true
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

    darwinPath=$(NIX_PATH=$nixPath nix-instantiate --find-file darwin) || true
    if ! test -e "$darwinPath"; then
        echo "[1;31merror: Changed <darwin> but target does not exist, aborting activation[0m" >&2
        echo "Add the darwin repo as a channel or set nix.nixPath:" >&2
        echo "$ sudo nix-channel --add https://github.com/LnL7/nix-darwin/archive/master.tar.gz darwin" >&2
        echo "$ sudo nix-channel --update" >&2
        echo >&2
        echo "or set" >&2
        echo >&2
        echo "    nix.nixPath = [ \"darwin=$(nix-instantiate --find-file darwin 2> /dev/null || echo '***')\" ];" >&2
        echo >&2
        exit 2
    fi

    nixpkgsPath=$(NIX_PATH=$nixPath nix-instantiate --find-file nixpkgs) || true
    if ! test -e "$nixpkgsPath"; then
        echo "[1;31merror: Changed <nixpkgs> but target does not exist, aborting activation[0m" >&2
        echo "Add a nixpkgs channel or set nix.nixPath:" >&2
        echo "$ sudo nix-channel --add http://nixos.org/channels/nixpkgs-unstable nixpkgs" >&2
        echo "$ sudo nix-channel --update" >&2
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
        echo >&2 "    sudo chown -R root:wheel /nix/var/nix/db"
        echo >&2
        echo >&2 "Otherwise:"
        echo >&2
        echo >&2 "    sudo chown -R $USER:staff /nix/store"
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

  nixStoreOptimiser = ''
    if test -O /nix/store; then
        echo "[1;31merror: A single-user install can't run optimiser as root, aborting activation[0m" >&2
        echo "Configure the optimiser to run as the current user:" >&2
        echo >&2
        echo "    nix.optimise.user = \"$USER\";" >&2
        echo >&2
        exit 2
    fi
  '';

  # TODO: Remove this a couple years down the line when we can assume
  # that anyone who cares about security has upgraded.
  oldSshAuthorizedKeysDirectory = ''
    if [[ -d /etc/ssh/authorized_keys.d ]]; then
        printf >&2 '\e[1;31merror: /etc/ssh/authorized_keys.d exists, aborting activation\e[0m\n'
        printf >&2 'SECURITY NOTICE: The previous implementation of the\n'
        printf >&2 '`users.users.<name>.openssh.authorizedKeys.*` options would not delete\n'
        printf >&2 'authorized keys files when the setting for a given user was removed.\n'
        printf >&2 '\n'
        printf >&2 "This means that if you previously stopped managing a user's authorized\n"
        printf >&2 'SSH keys with nix-darwin, or intended to revoke their access by\n'
        printf >&2 'removing the option, the previous set of keys could still be used to\n'
        printf >&2 'log in as that user.\n'
        printf >&2 '\n'
        printf >&2 'You can check the /etc/ssh/authorized_keys.d directory to see which\n'
        printf >&2 'keys were permitted; afterwards, please remove the directory and\n'
        printf >&2 're-run activation. The options continue to be supported and will now\n'
        printf >&2 'correctly permit only the keys in your current system configuration.\n'
        exit 2
    fi
  '';

  homebrewInstalled = ''
    if [[ ! -f ${escapeShellArg config.homebrew.brewPrefix}/brew && -z "''${INSTALLING_HOMEBREW:-}" ]]; then
        echo "[1;31merror: Using the homebrew module requires homebrew installed, aborting activation[0m" >&2
        echo "Homebrew doesn't seem to be installed. Please install homebrew separately." >&2
        echo "You can install homebrew using the following command:" >&2
        echo >&2
        echo '    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' >&2
        echo >&2
        exit 2
    fi
  '';

  # some mac devices, notably notebook do not support restartAfterPowerFailure option
  restartAfterPowerFailureIsSupported = ''
    if sudo /usr/sbin/systemsetup -getRestartPowerFailure | grep -q "Not supported"; then
       printf >&2 "\e[1;31merror: restarting after power failure is not supported on your machine\e[0m\n" >&2
       printf >&2 "Please ensure that \`power.restartAfterPowerFailure\` is not set.\n" >&2
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

    system.checks.verifyNixChannels = mkOption {
      type = types.bool;
      default = config.nix.channel.enable;
      description = "Whether to run the nix-channels validation checks.";
    };

    system.checks.verifyBuildUsers = mkOption {
      type = types.bool;
      default =
        (config.nix.useDaemon && !(config.nix.settings.auto-allocate-uids or false))
        || config.nix.configureBuildUsers;
      description = "Whether to run the Nix build users validation checks.";
    };

    system.checks.verifyMacOSVersion = mkOption {
      type = types.bool;
      default = true;
      description = "Whether to run the macOS version check.";
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
      (mkIf cfg.verifyMacOSVersion macOSVersion)
      (mkIf (cfg.verifyBuildUsers && !config.nix.configureBuildUsers) oldBuildUsers)
      (mkIf cfg.verifyBuildUsers buildUsers)
      (mkIf cfg.verifyBuildUsers preSequoiaBuildUsers)
      (mkIf config.nix.configureBuildUsers buildGroupID)
      nixDaemon
      nixStore
      (mkIf (config.nix.gc.automatic && config.nix.gc.user == null) nixGarbageCollector)
      (mkIf (config.nix.optimise.automatic && config.nix.optimise.user == null) nixStoreOptimiser)
      (mkIf cfg.verifyNixChannels nixChannels)
      nixInstaller
      (mkIf cfg.verifyNixPath nixPath)
      oldSshAuthorizedKeysDirectory
      (mkIf config.homebrew.enable homebrewInstalled)
      (mkIf (config.power.restartAfterPowerFailure != null) restartAfterPowerFailureIsSupported)
    ];

    system.activationScripts.checks.text = ''
      ${cfg.text}

      if [[ "''${checkActivation:-0}" -eq 1 ]]; then
        echo "ok" >&2
        exit 0
      fi
    '';

  };
}
