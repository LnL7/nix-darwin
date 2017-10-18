{ config, lib, pkgs, ... }:

with lib;

let

in

{
  options = {

    nix.profile = mkOption { internal = true; default = null; };

  };

  config = {

    assertions =
      [ { assertion = config.nix.profile == null; message = "nix.profile was renamed to nix.package"; }
      ];

    nix.package = mkIf (config.nix.profile != null) config.nix.profile;

  };
}
