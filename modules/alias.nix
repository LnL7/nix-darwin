{ config, lib, pkgs, ... }:

with lib;

let

in

{
  options = {

    networking.networkservices = mkOption { internal = true; default = null; };
    nix.profile = mkOption { internal = true; default = null; };
    security.enableAccessibilityAccess = mkOption { internal = true; default = null; };
    security.accessibilityPrograms = mkOption { internal = true; default = null; };

  };

  config = {

    assertions =
      [ { assertion = config.nix.profile == null; message = "nix.profile was renamed to nix.package"; }
        { assertion = config.security.enableAccessibilityAccess == null; message = "security.enableAccessibilityAccess was removed, it's broken since 10.12 because of SIP"; }
      ];

    warnings = mkIf (config.networking.networkservices != null) [
      "networking.networkservices was renamed to networking.knownNetworkServices"
    ];

    networking.knownNetworkServices = mkIf (config.networking.networkservices != null) config.networking.networkservices;

    nix.package = mkIf (config.nix.profile != null) config.nix.profile;

  };
}
