{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.users;

  isCreatedGroup = name: elem name cfg.knownGroups;
  isDeletedGroup = name: ! elem name (mapAttrsToList (n: v: v.name) cfg.groups);

  createdGroups = mapAttrsToList (n: v: v) (filterAttrs (n: v: isCreatedGroup v.name) cfg.groups);
  deletedGroups = filter (n: isDeletedGroup n) cfg.knownGroups;

  group =
    { name, ... }:
    {
      options = {
        gid = mkOption {
          type = mkOptionType {
            name = "gid";
            check = t: isInt t && t > 501;
          };
          description = "The group's GID.";
        };

        name = mkOption {
          type = types.str;
          description = ''
            The group's name. If undefined, the name of the attribute set
            will be used.
          '';
        };

        description = mkOption {
          type = types.str;
          default = "";
          description = "The group's description.";
        };
      };
      config = {
        name = mkDefault name;
      };
    };
in

{
  options = {
    users.knownGroups = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of groups that should be created and configured.";
    };

    users.groups = mkOption {
      type = types.loaOf (types.submodule group);
      default = {};
      description = "Configuration for groups.";
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
        else
          if [ "$g" -ne ${toString v.gid} ]; then
            echo "[1;31mwarning: existing group '${v.name}' has unexpected gid $g, skipping...[0m" >&2
          fi
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

  };
}
