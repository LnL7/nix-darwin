{ config, lib, pkgs, ... }:

with lib;

let

in

{
  options = {

    nix.profile = mkOption { internal = true; default = null; };
    security.enableAccessibilityAccess = mkOption { internal = true; default = null; };
    security.accessibilityPrograms = mkOption { internal = true; default = null; };

  };

  config = {

    assertions =
      [ { assertion = config.nix.profile == null; message = "nix.profile was renamed to nix.package"; }
        { assertion = config.security.enableAccessibilityAccess == null; message = "security.enableAccessibilityAccess was removed, it's broken since 10.12 because of SIP"; }
      ];

    nix.package = mkIf (config.nix.profile != null) config.nix.profile;

  };
}
