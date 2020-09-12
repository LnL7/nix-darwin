{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.users;

  group = import ./group.nix;
  user = import ./user.nix;

  toArguments = concatMapStringsSep " " (v: "'${v}'");
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

      ${concatMapStringsSep "\n" (v: ''
        ${optionalString cfg.forceRecreate ''
          g=$(dscl . -read '/Groups/${v.name}' PrimaryGroupID 2> /dev/null) || true
          g=''${g#PrimaryGroupID: }
          if [ "$g" -eq ${toString v.gid} ]; then
            echo "deleting group ${v.name}..." >&2
            dscl . -delete '/Groups/${v.name}' 2> /dev/null
          else
            echo "[1;31mwarning: existing group '${v.name}' has unexpected gid $g, skipping...[0m" >&2
          fi
        ''}

        g=$(dscl . -read '/Groups/${v.name}' PrimaryGroupID 2> /dev/null) || true
        g=''${g#PrimaryGroupID: }
        if [ -z "$g" ]; then
          echo "creating group ${v.name}..." >&2
          dscl . -create '/Groups/${v.name}' PrimaryGroupID ${toString v.gid}
          dscl . -create '/Groups/${v.name}' RealName '${v.description}'
          g=${toString v.gid}
        fi

        if [ "$g" -eq ${toString v.gid} ]; then
          g=$(dscl . -read '/Groups/${v.name}' GroupMembership 2> /dev/null) || true
          if [ "$g" != 'GroupMembership: ${concatStringsSep " " v.members}' ]; then
            echo "updating group members ${v.name}..." >&2
            dscl . -create '/Groups/${v.name}' GroupMembership ${toArguments v.members}
          fi
        else
          echo "[1;31mwarning: existing group '${v.name}' has unexpected gid $g, skipping...[0m" >&2
        fi
      '') createdGroups}

      ${concatMapStringsSep "\n" (name: ''
        g=$(dscl . -read '/Groups/${name}' PrimaryGroupID 2> /dev/null) || true
        g=''${g#PrimaryGroupID: }
        if [ -n "$g" ]; then
          if [ "$g" -gt 501 ]; then
            echo "deleting group ${name}..." >&2
            dscl . -delete '/Groups/${name}' 2> /dev/null
          else
            echo "[1;31mwarning: existing group '${name}' has unexpected gid $g, skipping...[0m" >&2
          fi
        fi
      '') deletedGroups}
    '';

    system.activationScripts.users.text = mkIf (cfg.knownUsers != []) ''
      echo "setting up users..." >&2

      ${concatMapStringsSep "\n" (v: ''
        ${optionalString cfg.forceRecreate ''
          u=$(dscl . -read '/Users/${v.name}' UniqueID 2> /dev/null) || true
          u=''${u#UniqueID: }
          if [ "$u" -eq ${toString v.uid} ]; then
            echo "deleting user ${v.name}..." >&2
            dscl . -delete '/Users/${v.name}' 2> /dev/null
          else
            echo "[1;31mwarning: existing user '${v.name}' has unexpected uid $u, skipping...[0m" >&2
          fi
        ''}

        u=$(dscl . -read '/Users/${v.name}' UniqueID 2> /dev/null) || true
        u=''${u#UniqueID: }
        if [ -z "$u" ]; then
          echo "creating user ${v.name}..." >&2
          dscl . -create '/Users/${v.name}' UniqueID ${toString v.uid}
          dscl . -create '/Users/${v.name}' PrimaryGroupID ${toString v.gid}
          dscl . -create '/Users/${v.name}' IsHidden ${if v.isHidden then "1" else "0"}
          dscl . -create '/Users/${v.name}' RealName '${v.description}'
          dscl . -create '/Users/${v.name}' NFSHomeDirectory '${v.home}'
          dscl . -create '/Users/${v.name}' UserShell '${v.shell}'
          ${optionalString v.createHome "createhomedir -cu '${v.name}'"}
        else
          if [ "$u" -ne ${toString v.uid} ]; then
            echo "[1;31mwarning: existing user '${v.name}' has unexpected uid $u, skipping...[0m" >&2
          fi
        fi
      '') createdUsers}

      ${concatMapStringsSep "\n" (name: ''
        u=$(dscl . -read '/Users/${name}' UniqueID 2> /dev/null) || true
        u=''${u#UniqueID: }
        if [ -n "$u" ]; then
          if [ "$u" -gt 501 ]; then
            echo "deleting user ${name}..." >&2
            dscl . -delete '/Users/${name}' 2> /dev/null
          else
            echo "[1;31mwarning: existing user '${name}' has unexpected uid $u, skipping...[0m" >&2
          fi
        fi
      '') deletedUsers}
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
