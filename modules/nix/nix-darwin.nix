{ config, pkgs, lib, ... }:

let
  nix-tools = pkgs.callPackage ../../pkgs/nix-tools {
    inherit (config.system) profile;
    inherit (config.environment) systemPath;
    nixPackage = config.nix.package;
  };

  darwin-uninstaller = pkgs.callPackage ../../pkgs/darwin-uninstaller { };

  inherit (nix-tools) darwin-option darwin-rebuild darwin-version;
in

{
  options = {
    system.includeUninstaller = lib.mkOption {
      type = lib.types.bool;
      internal = true;
      default = true;
    };
  };

  config = {
    environment.systemPackages =
      [ # Include nix-tools by default
        darwin-option
        darwin-rebuild
        darwin-version
      ] ++ lib.optional config.system.includeUninstaller darwin-uninstaller;

    system.build = {
      inherit darwin-option darwin-rebuild darwin-version;
    };
  };
}
