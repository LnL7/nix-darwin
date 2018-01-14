{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.users;

  group = import ./group.nix;
  user = import ./user.nix;

  toArguments = concatMapStringsSep " " (v: "'${v}'");

  isCreated = list: name: elem name list;
  isDeleted = attrs: name: ! elem name (mapAttrsToList (n: v: v.name) attrs);

  createdGroups = mapAttrsToList (n: v: v) (filterAttrs (n: v: isCreated cfg.knownGroups v.name) cfg.groups);
  createdUsers = mapAttrsToList (n: v: v) (filterAttrs (n: v: isCreated cfg.knownUsers v.name) cfg.users);
  deletedGroups = filter (n: isDeleted cfg.groups n) cfg.knownGroups;
  deletedUsers = filter (n: isDeleted cfg.users n) cfg.knownUsers;
in

{
  options = {
    users.knownGroups = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of groups that should be created and configured.";
    };

    users.knownUsers = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of users that should be created and configured.";
    };

    users.groups = mkOption {
      type = types.loaOf (types.submodule group);
      default = {};
      description = "Configuration for groups.";
    };

    users.users = mkOption {
      type = types.loaOf (types.submodule user);
      default = {};
      description = "Configuration for users.";
    };
  };

  config = {

    system.activationScripts.groups.text = mkIf (cfg.knownGroups != []) ''
      echo "setting up groups..." >&2

      ${concatMapStringsSep "\n" (v: ''
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

  };
}
