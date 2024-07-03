{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.users;

  group = import ./group.nix;
  user = import ./user.nix;

  toArguments = concatMapStringsSep " " (v: "'${v}'");

  packageUsers = filterAttrs (_: u: u.packages != []) cfg.users;

  # convert a valid argument to user.shell into a string that points to a shell
  # executable. Logic copied from modules/system/shells.nix.
  shellPath = v:
    if types.shellPackage.check v
    then "/run/current-system/sw${v.shellPath}"
    else v;

  dsclSearch = path: key: val: ''dscl . -search ${path} ${key} ${val} | /usr/bin/cut -s -w -f 1 | awk "NF"'';
  diffArrays = a1: a2: ''echo ''${${a1}[@]} ''${${a1}[@]} ''${${a2}[@]} | tr ' ' '\n' | sort | uniq -u'';
  groupMembership = g: ''
    dscl . -list /Users | while read user; do
      printf '%s ' "$user";
      dsmemberutil checkmembership -U "$user" -G "${g}";
    done | grep "is a member" | /usr/bin/cut -s -w -f 1
  '';

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

    users.mutableUsers = mkOption {
      type = types.bool;
      default = true;
      description = ''
        If set to true, you are free to add new users
        and groups to the system with the ordinary sysadminctl and dscl commands.
        The initial password for a user will be set according to users.users,
        but existing passwords will not be changed.
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
        assertion = !cfg.mutableUsers -> !cfg.forceRecreate ->
          any id (mapAttrsToList (n: v:
            (v.password != null && v.isTokenUser && v.isAdminUser)
          ) cfg.users);
        message = ''
          You must set a combined admin and token user with a password
          to prevent being locked out of your system.
          If you really want to be locked out of your system, set users.forceRecreate = true;
          However, you are most probably better off by setting users.mutableUsers = true; and
          manually changing the user with dscl.
        '';
      }
    ] ++ (mapAttrsToList (n: v: {
      assertion = let
        isEffectivelySystemUser = hasPrefix "_" n && (
          v.isSystemUser || (v.uid != null && (v.uid >= 200 && v.uid <= 400))
        );
      in xor isEffectivelySystemUser v.isNormalUser;
        message = ''
          Exactly one of users.users.${n}.isSystemUser and users.users.${n}.isNormalUser must be set.
          System user name must start with '_' and uid in range (200-400).
        '';
    }) cfg.users);

    system.activationScripts.groups.text = mkIf ((length (attrNames cfg.groups)) > 0) ''
      echo "setting up groups..." >&2

      g=(${toArguments (attrNames cfg.groups)})
      nix_g=($(${dsclSearch "/Groups" "NixDeclarative" "true"}))

      ${optionalString (!cfg.mutableUsers || cfg.forceRecreate) ''
        # Delete old nix managed groups not in config
        deleted=(${if cfg.forceRecreate then "$g" else "$(${diffArrays "g" "nix_g"})"})
        for group in ''${deleted[@]}; do
          echo "deleting group $group..."
          dscl . -delete "/Groups/$group"
        done
        unset deleted
      ''}

      # Create group properties according to config.
      # Skip group if users.mutableUsers = true and group already exists.
      ${concatMapStringsSep "\n" (v: v) (mapAttrsToList (n: v: ''
        ignore=(${if cfg.mutableUsers
          then "$(dscl . -read /Groups/${n} PrimaryGroupID 2> /dev/null || true)"
          else ""
        })
        if [ -z "$ignore" ]; then
          echo "creating group ${n}..." >&2
          dscl . -create '/Groups/${n}' PrimaryGroupID ${toString v.gid}
          dscl . -create '/Groups/${n}' RealName '${v.description}'
          dscl . -create '/Groups/${n}' GroupMembership ${toArguments v.members}
          dscl . -create '/Groups/${n}' NixDeclarative 'true'
        fi
      '') cfg.groups)}
    '';

    system.activationScripts.users.text = mkIf ((length (attrNames cfg.users)) > 0) ''
      echo "setting up users..." >&2

      u=(${toArguments (attrNames cfg.users)})
      nix_u=($(${dsclSearch "/Users" "NixDeclarative" "true"}))
      admins=($(${groupMembership "admin"}))
      admins=(''${admins[@]/root})

      ${optionalString (!cfg.mutableUsers || cfg.forceRecreate) ''
        # Delete old nix managed users not in config
        deleted=(${if cfg.forceRecreate then "$u" else "$(${diffArrays "u" "nix_u"})"})
        for user in ''${deleted[@]}; do
          if [ $(wc -w <<<''${admins[@]/$user}) -eq 0 ]; then
            echo "[1;31mwarning: user $user is last user in admin group, skipping...[0m" >&2
          else
            echo "deleting user $user..."
            # '-keepHome' doesn't always work so archive the home dir manually
            cp -ax "/Users/$user" "/Users/$user (Deleted)" 2>/dev/null || true
            sysadminctl -deleteUser "$user" 2>/dev/null
            admins=(''${admins[@]/$user})
          fi
        done
        unset deleted
      ''}

      # Get admins with secure tokens for management of regular token users
      tokenAdmins=($(for user in "''${admins[@]}"; do
        printf '%s ' "$user";
        sysadminctl -secureTokenStatus "$user" 2>/dev/stdout;
      done | grep "is ENABLED" | /usr/bin/cut -s -w -f 1))

      # Create and overwrite user properties according to config.
      # Skip overwrite if users.mutableUsers = true,
      # users.forceRecreate = false, and user already exists.
      ${concatMapStringsSep "\n" (v: v) (mapAttrsToList (n: v: ''
        ignore=("$(dscl . -read /Users/${n} UniqueID 2> /dev/null || true)")
        force="${if (!cfg.mutableUsers && cfg.forceRecreate) then "true" else ""}"
        mutable="${if cfg.mutableUsers then "true" else ""}"

        # Always create users that don't exist
        if [ -z "$ignore" ]; then
          echo "creating user ${v.name}..." >&2
          # Use sysadminctl to ensure all macOS user attributes are set.
          # Otherwise, user management might break in System Settings with just dscl.
          ${concatStringsSep " " [
            "sysadminctl -addUser '${v.name}'"
            "-shell ${lib.escapeShellArg (shellPath v.shell)}"
            "${optionalString (v.uid != null) "-UID ${toString v.uid}"}"
            "${optionalString (v.gid != null) "-GID ${toString v.gid}"}"
            "${optionalString (v.description != "") "-fullName '${v.description}'"}"
            "${optionalString (v.home != "/Users/${v.name}") "-home '${v.home}'"}"
            "${optionalString (v.password != null) "-password '${v.password}'"}"
            "${optionalString v.isSystemUser "-roleAccount"}"
            "${optionalString v.isAdminUser "-admin"}"
          ]}
          dscl . -create '/Users/${v.name}' IsHidden ${if v.isHidden then "1" else "0"}
          ${optionalString v.createHome "createhomedir -cu '${v.name}'"}
          ${
             optionalString v.isTokenUser ''
               # Only admin with token can set a token for a user
               sysadminctl -adminUser "$(echo $tokenAdmins | head -n 1)" -adminPassword - \
                -secureTokenOn '${v.name}' -password '${if v.password == null then "-" else "${v.password}"}'
             ''
           }
        elif [ -n "$force" ]; then
          dscl . -create '/Users/${v.name}' UniqueID ${toString v.uid}
          dscl . -create '/Users/${v.name}' PrimaryGroupID ${toString v.gid}
          dscl . -create '/Users/${v.name}' IsHidden ${if v.isHidden then "1" else "0"}
          dscl . -create '/Users/${v.name}' RealName '${v.description}'
          dscl . -create '/Users/${v.name}' NFSHomeDirectory '${v.home}'
          dscl . -create '/Users/${v.name}' UserShell ${lib.escapeShellArg (shellPath v.shell)}
          ${optionalString v.isAdminUser "dscl . -merge '/Groups/admin' GroupMembership '${v.name}'"}
          ${optionalString v.createHome "createhomedir -cu '${v.name}'"}
        elif [ -z "$mutable" ]; then
          isTokenUser=$(sysadminctl -secureTokenStatus '${v.name}' 2>/dev/stdout \
          | grep -o "is ENABLED" | wc -w)
          # Admin with token is needed to reset user with token
          if [ "$isTokenUser" -gt 0 ]; then
            sysadminctl -adminUser "$(echo $tokenAdmins | head -n 1)" -adminPassword - \
            -resetPasswordFor '${v.name}' -newPassword "${v.password}"
          else
            sysadminctl -resetPasswordFor '${v.name}' -newPassword "${v.password}"
          fi
          unset isTokenUser
          dscl . -create '/Users/${v.name}' IsHidden ${if v.isHidden then "1" else "0"}
        fi
        # Always set managed user NixDeclarative property if Nix is managing the user
        dscl . -create '/Users/${v.name}' NixDeclarative 'true'
      '') cfg.users)}
    '';

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
