{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.users;

  isCreatedUser = name: elem name cfg.knownUsers;
  isDeletedUser = name: ! elem name (mapAttrsToList (n: v: v.name) cfg.users);

  createdUsers = mapAttrsToList (n: v: v) (filterAttrs (n: v: isCreatedUser v.name) cfg.users);
  deletedUsers = filter (n: isDeletedUser n) cfg.knownUsers;

  user =
    { name, ... }:
    {
      options = {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Whether this user should be created.";
        };

        name = mkOption {
          type = types.str;
          description = ''
            The name of the user account. If undefined, the name of the
            attribute set will be used.
          '';
        };

        description = mkOption {
          type = types.str;
          default = "";
          example = "Alice Q. User";
          description = ''
            A short description of the user account, typically the
            user's full name.
          '';
        };

        uid = mkOption {
          type = types.int;
          description = "The user's UID.";
        };

        gid = mkOption {
          type = types.int;
          default = 20;
          description = "The user's primary group.";
        };

        isHidden = mkOption {
          type = types.bool;
          default = false;
          description = "Whether to make the user account hidden.";
        };

        # extraGroups = mkOption {
        #   type = types.listOf types.str;
        #   default = [];
        #   description = "The user's auxiliary groups.";
        # };

        home = mkOption {
          type = types.path;
          default = "/var/empty";
          description = "The user's home directory.";
        };

        shell = mkOption {
          type = types.either types.shellPackage types.path;
          default = "/sbin/nologin";
          example = literalExample "pkgs.bashInteractive";
          description = "The user's shell.";
        };
      };
      config = {
        name = mkDefault name;
      };
    };
in

{
  options = {
    users.knownUsers = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of users that should be created and configured.";
    };

    users.users = mkOption {
      type = types.loaOf (types.submodule user);
      default = {};
      description = "Configuration for users.";
    };
  };

  config = {

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
