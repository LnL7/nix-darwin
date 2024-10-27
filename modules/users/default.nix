{ config, lib, pkgs, ... }:

let
  inherit (lib) concatStringsSep concatMapStringsSep elem filter filterAttrs
    mapAttrs' mapAttrsToList mkIf mkMerge mkOption mkOrder optionalString types;

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
    assertions = [
      {
        # We don't check `root` like the rest of the users as on some systems `root`'s
        # home directory is set to `/var/root /private/var/root`
        assertion = cfg.users ? root -> (cfg.users.root.home == null || cfg.users.root.home == "/var/root");
        message = "`users.users.root.home` must be set to either `null` or `/var/root`.";
      }
    ];

    users.gids = mkMerge gids;
    users.uids = mkMerge uids;

    # NOTE: We put this in `system.checks` as we want this to run first to avoid partial activations
    # however currently that runs at user level activation as that runs before system level activation
    # TODO: replace `$USER` with `$SUDO_USER` when system.checks runs from system level
    system.checks.text = lib.mkAfter ''
      ensurePerms() {
        homeDirectory=$(dscl . -read /Users/nobody NFSHomeDirectory)
        homeDirectory=''${homeDirectory#NFSHomeDirectory: }

        if ! sudo dscl . -change /Users/nobody NFSHomeDirectory "$homeDirectory" "$homeDirectory" &> /dev/null; then
          if [[ -n "$SSH_CONNECTION" ]]; then
            printf >&2 '\e[1;31merror: users cannot be %s over SSH without Full Disk Access, aborting activation\e[0m\n' "$2"
            printf >&2 'The user %s could not be %s as `darwin-rebuild` was not executed with Full Disk Access over SSH.\n' "$1" "$2"
            printf >&2 'You can either:\n'
            printf >&2 '\n'
            printf >&2 '  grant Full Disk Access to all programs run over SSH\n'
            printf >&2 '\n'
            printf >&2 'or\n'
            printf >&2 '\n'
            printf >&2 '  run `darwin-rebuild` in a graphical session.\n'
            printf >&2 '\n'
            printf >&2 'The option "Allow full disk access for remote users" can be found by\n'
            printf >&2 'navigating to System Settings > General > Sharing > Remote Login\n'
            printf >&2 'and then pressing on the i icon next to the switch.\n'
            exit 1
          else
            # The TCC service required to change home directories is `kTCCServiceSystemPolicySysAdminFiles`
            # and we can reset it to ensure the user gets another prompt
            tccutil reset SystemPolicySysAdminFiles > /dev/null

            if ! sudo dscl . -change /Users/nobody NFSHomeDirectory "$homeDirectory" "$homeDirectory" &> /dev/null; then
              printf >&2 '\e[1;31merror: permission denied when trying to %s user %s, aborting activation\e[0m\n' "$2" "$1"
              printf >&2 '`darwin-rebuild` requires permissions to administrate your computer,\n' "$1" "$2"
              printf >&2 'please accept the dialog that pops up.\n'
              printf >&2 '\n'
              printf >&2 'If you do not wish to be prompted every time `darwin-rebuild updates your users,\n'
              printf >&2 'you can grant Full Disk Access to your terminal emulator in System Settings.\n'
              printf >&2 '\n'
              printf >&2 'This can be found in System Settings > Privacy & Security > Full Disk Access.\n'
              exit 1
            fi
          fi

        fi
      }

      ensureDeletable() {
        # TODO: add `darwin.primaryUser` as well
        if [[ "$1" == "$USER" ]]; then
          printf >&2 '\e[1;31merror: refusing to delete the user calling `darwin-rebuild` (%s), aborting activation\e[0m\n', "$1"
          exit 1
        elif [[ "$1" == "root" ]]; then
          printf >&2 '\e[1;31merror: refusing to delete `root`, aborting activation\e[0m\n'
          exit 1
        fi

        ensurePerms "$1" delete
      }

      ${concatMapStringsSep "\n" (v: let
        name = lib.escapeShellArg v.name;
        dsclUser = lib.escapeShellArg "/Users/${v.name}";
      in ''
        ${optionalString cfg.forceRecreate ''
          u=$(id -u ${name} 2> /dev/null) || true
          if [[ "$u" -eq ${toString v.uid} ]]; then
            # TODO: add `darwin.primaryUser` as well
            if [[ ${name} != "$USER" && ${name} != "root" ]]; then
              ensureDeletable ${name}
            fi
          fi
        ''}

        u=$(id -u ${name} 2> /dev/null) || true
        if ! [[ -n "$u" && "$u" -ne "${toString v.uid}" ]]; then
          if [ -z "$u" ]; then
            ensurePerms ${name} create
          fi

          ${optionalString (v.home != null && v.name != "root") ''
            homeDirectory=$(dscl . -read ${dsclUser} NFSHomeDirectory)
            homeDirectory=''${homeDirectory#NFSHomeDirectory: }
            if [[ ${lib.escapeShellArg v.home} != "$homeDirectory" ]]; then
              printf >&2 '\e[1;31merror: config contains the wrong home directory for %s, aborting activation\e[0m\n' ${name}
              printf >&2 'nix-darwin does not support changing the home directory of existing users.
              printf >&2 '\n'
              printf >&2 'Please set:\n'
              printf >&2 '\n'
              printf >&2 '    users.users.%s.home = "%s";\n' ${name} "$homeDirectory"
              printf >&2 '\n'
              printf >&2 'or remove it from your configuration.\n'
              exit 1
            fi
          ''}
        fi
      '') createdUsers}

      ${concatMapStringsSep "\n" (name: ''
        u=$(id -u ${lib.escapeShellArg name} 2> /dev/null) || true
        if [ -n "$u" ]; then
          if [ "$u" -gt 501 ]; then
            ensureDeletable ${lib.escapeShellArg name}
          fi
        fi
      '') deletedUsers}
    '';

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
            dscl . -delete ${dsclGroup}
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
            dscl . -delete ${dsclGroup}
          else
            echo "[1;31mwarning: existing group '${name}' has unexpected gid $g, skipping...[0m" >&2
          fi
        fi
      '') deletedGroups}
    '';

    system.activationScripts.users.text = mkIf (cfg.knownUsers != []) ''
      echo "setting up users..." >&2

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
              dscl . -delete ${dsclUser}
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

            sysadminctl -addUser ${lib.escapeShellArgs ([
              v.name
              "-UID" v.uid
              "-GID" v.gid ]
              ++ (lib.optionals (v.description != null) [ "-fullName" v.description ])
              ++ (lib.optionals (v.home != null) [ "-home" v.home ])
              ++ [ "-shell" (if v.shell != null then shellPath v.shell else "/usr/bin/false") ])} 2> /dev/null

            # We need to check as `sysadminctl -addUser` still exits with exit code 0 when there's an error
            if ! id ${name} &> /dev/null; then
              printf >&2 '\e[1;31merror: failed to create user %s, aborting activation\e[0m\n' ${name}
              exit 1
            fi

            dscl . -create ${dsclUser} IsHidden ${if v.isHidden then "1" else "0"}

            # `sysadminctl -addUser` won't create the home directory if we use the `-home`
            # flag so we need to do it ourselves
            ${optionalString (v.home != null && v.createHome) "createhomedir -cu ${name} > /dev/null"}
          fi

          # Update properties on known users to keep them inline with configuration
          dscl . -create ${dsclUser} PrimaryGroupID ${toString v.gid}
          ${optionalString (v.description != null) "dscl . -create ${dsclUser} RealName ${lib.escapeShellArg v.description}"}
          ${optionalString (v.shell != null) "dscl . -create ${dsclUser} UserShell ${lib.escapeShellArg (shellPath v.shell)}"}
        fi
      '') createdUsers}

      ${concatMapStringsSep "\n" (name: ''
        u=$(id -u ${lib.escapeShellArg name} 2> /dev/null) || true
        if [ -n "$u" ]; then
          if [ "$u" -gt 501 ]; then
            echo "deleting user ${name}..." >&2
            dscl . -delete ${lib.escapeShellArg "/Users/${name}"}
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
