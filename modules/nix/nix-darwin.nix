{ config, pkgs, lib, ... }:

let
  nix-tools = pkgs.callPackage ../../pkgs/nix-tools {
    inherit (config.system) profile;
    inherit (config.environment) systemPath;
    nixPath = lib.optionalString config.nix.enable (lib.concatStringsSep ":" config.nix.nixPath);
  };

  darwin-uninstaller = pkgs.callPackage ../../pkgs/darwin-uninstaller { };

  inherit (nix-tools) darwin-option darwin-rebuild darwin-version;
in

{
  options.system = {
    disableInstallerTools = lib.mkOption {
      type = lib.types.bool;
      internal = true;
      default = false;
      description = ''
        Disable darwin-rebuild and darwin-option. This is useful to shrink
        systems which are not expected to rebuild or reconfigure themselves.
        Use at your own risk!
    '';
    };

    includeUninstaller = lib.mkOption {
      type = lib.types.bool;
      internal = true;
      default = true;
    };
  };

  config = {
    environment.systemPackages =
      [ darwin-version ]
      ++ lib.optionals (!config.system.disableInstallerTools) [
        darwin-option
        darwin-rebuild
      ] ++ lib.optional config.system.includeUninstaller darwin-uninstaller;

    system.build = {
      inherit darwin-option darwin-rebuild darwin-version;
    };
  };
}
