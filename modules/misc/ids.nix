# Based on: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/misc/ids.nix

# This module defines the global list of uids and gids.  We keep a
# central list to prevent id collisions.

# IMPORTANT!
# We only add static uids and gids for services where it is not feasible
# to change uids/gids on service start, in example a service with a lot of
# files.

{ lib, ... }:

let
  inherit (lib) types;
in
{
  options = {

    ids.uids = lib.mkOption {
      internal = true;
      description = lib.mdDoc ''
        The user IDs used in NixOS.
      '';
      type = types.attrsOf types.int;
    };

    ids.gids = lib.mkOption {
      internal = true;
      description = lib.mdDoc ''
        The group IDs used in NixOS.
      '';
      type = types.attrsOf types.int;
    };

  };


  config = {

    ids.uids = {
      nixbld = 300;
    };

    ids.gids = {
      nixbld = 30000;
    };

  };

}
