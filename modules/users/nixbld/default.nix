{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.users;

  createdGroups = mapAttrsToList (n: v: v.name) cfg.groups;
  createdUsers = mapAttrsToList (n: v: v.name) cfg.users;

  mkUsers = f: genList (x: f (x + 1)) cfg.nix.nrBuildUsers;

  buildUsers = mkUsers (i: {
    name = "nixbld${toString i}";
    uid = 30000 + i;
    gid = 30000;
    description = "Nix build user ${toString i}";
  });

  buildGroups = [{
    name = "nixbld";
    gid = 30000;
    description = "Nix build group for nix-daemon";
    members = map (v: v.name) buildUsers;
  }];
in

{
  options = {
    users.nix.configureBuildUsers = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Configuration for nixbld group and users.
        NOTE: This does not work unless knownGroups/knownUsers is set.
      '';
    };

    users.nix.nrBuildUsers = mkOption {
      type = mkOptionType {
        name = "integer";
        check = t: isInt t && t > 1;
      };
      default = 10;
      description = "Number of nixbld user accounts created to perform secure concurrent builds.";
    };
  };

  config = {

    assertions = [
      { assertion = elem "nixbld" cfg.knownGroups -> elem "nixbld" createdGroups; message = "refusing to delete group nixbld in users.knownGroups, this would break nix"; }
      { assertion = elem "nixbld1" cfg.knownUsers -> elem "nixbld1" createdUsers; message = "refusing to delete user nixbld1 in users.knownUsers, this would break nix"; }
      { assertion = cfg.groups ? "nixbld" -> cfg.groups.nixbld.members != []; message = "refusing to remove all members from nixbld group, this would break nix"; }
    ];

    users.groups = mkIf cfg.nix.configureBuildUsers buildGroups;
    users.users = mkIf cfg.nix.configureBuildUsers buildUsers;

  };
}

