{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.users;

  group = import ./group.nix;
  user = import ./user.nix;

  toGID = v: { "${toString v.gid}" = v.name; };
  toUID = v: { "${toString v.uid}" = v.name; };

  isCreated = list: name: elem name list;
  isDeleted = attrs: name: ! elem name (mapAttrsToList (n: v: v.name) attrs);

  gids = mapAttrsToList (n: toGID) (filterAttrs (n: v: isCreated cfg.knownGroups v.name) cfg.groups);
  uids = mapAttrsToList (n: toUID) (filterAttrs (n: v: isCreated cfg.knownUsers v.name) cfg.users);

  createdGroups = mapAttrsToList (n: v: cfg.groups."${v}") cfg.gids;
  createdUsers = mapAttrsToList (n: v: cfg.users."${v}") cfg.uids;
  deletedGroups = filter (n: isDeleted cfg.groups n) cfg.knownGroups;
  deletedUsers = filter (n: isDeleted cfg.users n) cfg.knownUsers;

  packageUsers = filterAttrs (_: u: u.packages != []) cfg.users;

  # convert a valid argument to user.shell into a string that points to a shell
  # executable. Logic copied from modules/system/shells.nix.
  shellPath = v:
    if types.shellPackage.check v
    then "/run/current-system/sw${v.shellPath}"
    else v;

  systemShells =
    let
      shells = mapAttrsToList (_: u: u.shell) cfg.users;
    in
      filter types.shellPackage.check shells;

in

{
  options = {
    users.knownGroups = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        List of groups owned and managed by nix-darwin. Used to indicate
        what users are safe to create/delete based on the configuration.
        Don't add system groups to this.
      '';
    };

    users.knownUsers = mkOption {
      type = types.listOf types.str;
      default = [];
      description = ''
        List of users owned and managed by nix-darwin. Used to indicate
        what users are safe to create/delete based on the configuration.
        Don't add the admin user or other system users to this.
      '';
    };

    users.groups = mkOption {
      type = types.attrsOf (types.submodule group);
      default = {};
      description = "Configuration for groups.";
    };

    users.users = mkOption {
      type = types.attrsOf (types.submodule user);
      default = {};
      description = "Configuration for users.";
    };

    users.gids = mkOption {
      internal = true;
      type = types.attrsOf types.str;
      default = {};
    };

    users.uids = mkOption {
      internal = true;
      type = types.attrsOf types.str;
      default = {};
    };

    users.forceRecreate = mkOption {
      internal = true;
      type = types.bool;
      default = false;
      description = "Remove and recreate existing groups/users.";
    };
  };

  config = {

    users.gids = mkMerge gids;
    users.uids = mkMerge uids;

    system.activationScripts.groups.text = mkIf (cfg.knownGroups != []) ''
      echo "setting up groups..." >&2

      ${concatMapStringsSep "\n" (v: let
        dsclGroup = lib.escapeShellArg "/Groups/${v.name}";
      in ''
        ${optionalString cfg.forceRecreate ''
          g=$(dscl . -read ${dsclGroup} PrimaryGroupID 2> /dev/null) || true
          g=''${g#PrimaryGroupID: }
          if [[ "$g" -eq ${toString v.gid} ]]; then
            echo "deleting group ${v.name}..." >&2
            dscl . -delete ${dsclGroup} 2> /dev/null
          else
            echo "[1;31mwarning: existing group '${v.name}' has unexpected gid $g, skipping...[0m" >&2
          fi
        ''}

        g=$(dscl . -read ${dsclGroup} PrimaryGroupID 2> /dev/null) || true
        g=''${g#PrimaryGroupID: }
        if [ -z "$g" ]; then
          echo "creating group ${v.name}..." >&2
          dscl . -create ${dsclGroup} PrimaryGroupID ${toString v.gid}
          dscl . -create ${dsclGroup} RealName ${lib.escapeShellArg v.description}
          g=${toString v.gid}
        fi

        if [ "$g" -eq ${toString v.gid} ]; then
          g=$(dscl . -read ${dsclGroup} GroupMembership 2> /dev/null) || true
          if [ "$g" != 'GroupMembership: ${concatStringsSep " " v.members}' ]; then
            echo "updating group members ${v.name}..." >&2
            dscl . -create ${dsclGroup} GroupMembership ${lib.escapeShellArgs v.members}
          fi
        else
          echo "[1;31mwarning: existing group '${v.name}' has unexpected gid $g, skipping...[0m" >&2
        fi
      '') createdGroups}

      ${concatMapStringsSep "\n" (name: let
        dsclGroup = lib.escapeShellArg "/Groups/${name}";
      in ''
        g=$(dscl . -read ${dsclGroup} PrimaryGroupID 2> /dev/null) || true
        g=''${g#PrimaryGroupID: }
        if [ -n "$g" ]; then
          if [ "$g" -gt 501 ]; then
            echo "deleting group ${name}..." >&2
            dscl . -delete ${dsclGroup} 2> /dev/null
          else
            echo "[1;31mwarning: existing group '${name}' has unexpected gid $g, skipping...[0m" >&2
          fi
        fi
      '') deletedGroups}
    '';

    system.activationScripts.users.text = mkIf (cfg.knownUsers != []) ''
      echo "setting up users..." >&2

      requireFDA() {
        fullDiskAccess=false

        if cat /Library/Preferences/com.apple.TimeMachine.plist > /dev/null 2>&1; then
          fullDiskAccess=true
        fi

        if [[ "$fullDiskAccess" != true ]]; then
          printf >&2 '\e[1;31merror: users cannot be %s without Full Disk Access, aborting activation\e[0m\n' "$2"
          printf >&2 'The user %s could not be %s as `darwin-rebuild` was not executed with Full Disk Access.\n' "$1" "$2"
          printf >&2 '\n'
          printf >&2 'Opening "Privacy & Security" > "Full Disk Access" in System Settings\n'
          printf >&2 '\n'
          # This command will fail if run as root and System Settings is already running
          # even if System Settings was launched by root.
          sudo -u $SUDO_USER open "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"

          if [[ -n "$SSH_CONNECTION" ]]; then
            printf >&2 'Please enable Full Disk Access for programs over SSH by flipping\n'
            printf >&2 'the switch for `sshd-keygen-wrapper`.\n'
          else
            printf >&2 'Please enable Full Disk Access for your terminal emulator by flipping\n'
            printf >&2 'the switch in System Settings.\n'
          fi

          exit 1
        fi
      }

      deleteUser() {
        # FIXME: add `darwin.primaryUser` as well
        if [[ "$1" == "$SUDO_USER" ]]; then
          printf >&2 '\e[1;31merror: refusing to delete the user calling `darwin-rebuild` (%s), aborting activation\e[0m\n', "$1"
          exit 1
        elif [[ "$1" == "root" ]]; then
          printf >&2 '\e[1;31merror: refusing to delete `root`, aborting activation\e[0m\n', "$1"
          exit 1
        fi

        requireFDA "$1" deleted

        dscl . -delete "/Users/$1" 2> /dev/null

        # `dscl . -delete` should exit with a non-zero exit code when there's an error, but we'll leave
        # this code here just in case and for when we switch to `sysadminctl -deleteUser`
        # We need to check as `sysadminctl -deleteUser` still exits with exit code 0 when there's an error
        if id "$1" &> /dev/null; then
          printf >&2 '\e[1;31merror: failed to delete user %s, aborting activation\e[0m\n', "$1"
          exit 1
        fi
      }

      ${concatMapStringsSep "\n" (v: let
        name = lib.escapeShellArg v.name;
        dsclUser = lib.escapeShellArg "/Users/${v.name}";
      in ''
        ${optionalString cfg.forceRecreate ''
          u=$(id -u ${name} 2> /dev/null) || true
          if [[ "$u" -eq ${toString v.uid} ]]; then
            # TODO: add `darwin.primaryUser` as well
            if [[ ${name} == "$SUDO_USER" ]]; then
              printf >&2 '[1;31mwarning: not going to recreate the user calling `darwin-rebuild` (%s), skipping...[0m\n' "$SUDO_USER"
            elif [[ ${name} == "root" ]]; then
              printf >&2 '[1;31mwarning: not going to recreate root, skipping...[0m\n'
            else
              printf >&2 'deleting user ${v.name}...\n'
              deleteUser ${name}
            fi
          else
            echo "[1;31mwarning: existing user '${v.name}' has unexpected uid $u, skipping...[0m" >&2
          fi
        ''}

        u=$(id -u ${name} 2> /dev/null) || true
        if [[ -n "$u" && "$u" -ne "${toString v.uid}" ]]; then
          echo "[1;31mwarning: existing user '${v.name}' has unexpected uid $u, skipping...[0m" >&2
        else
          if [ -z "$u" ]; then
            echo "creating user ${v.name}..." >&2

            requireFDA ${name} "created"

            sysadminctl -addUser ${lib.escapeShellArgs ([ v.name "-UID" v.uid "-GID" v.gid ] ++ (lib.optionals (v.description != null) [ "-fullName" v.description ]) ++ [ "-home" v.home "-shell" (shellPath v.shell) ])} 2> /dev/null

            # We need to check as `sysadminctl -addUser` still exits with exit code 0 when there's an error
            if ! id ${name} &> /dev/null; then
              printf >&2 '\e[1;31merror: failed to create user %s, aborting activation\e[0m\n' ${name}
              exit 1
            fi

            dscl . -create ${dsclUser} IsHidden ${if v.isHidden then "1" else "0"}
            ${optionalString v.createHome "createhomedir -cu ${name}"}
          fi
          # Always set the shell path, in case it was updated
          dscl . -create ${dsclUser} UserShell ${lib.escapeShellArg (shellPath v.shell)}
        fi
      '') createdUsers}

      ${concatMapStringsSep "\n" (name: ''
        u=$(id -u ${lib.escapeShellArg name} 2> /dev/null) || true
        if [ -n "$u" ]; then
          if [ "$u" -gt 501 ]; then
            echo "deleting user ${name}..." >&2
            deleteUser ${lib.escapeShellArg name}
          else
            echo "[1;31mwarning: existing user '${name}' has unexpected uid $u, skipping...[0m" >&2
          fi
        fi
      '') deletedUsers}
    '';

    # Install all the user shells
    environment.systemPackages = systemShells;

    environment.etc = mapAttrs' (name: { packages, ... }: {
      name = "profiles/per-user/${name}";
      value.source = pkgs.buildEnv {
        name = "user-environment";
        paths = packages;
        inherit (config.environment) pathsToLink extraOutputsToInstall;
        inherit (config.system.path) postBuild;
      };
    }) packageUsers;

    environment.profiles = mkIf (packageUsers != {}) (mkOrder 900 [ "/etc/profiles/per-user/$USER" ]);
  };
}
