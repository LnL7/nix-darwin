{ config, pkgs, lib, ... }:

let
  nix-tools = pkgs.callPackage ../../pkgs/nix-tools {
    inherit (config.system) profile;
    inherit (config.environment) systemPath;
    nixPath = lib.optionalString config.nix.enable (lib.concatStringsSep ":" config.nix.nixPath);
  };

  darwin-uninstaller = pkgs.callPackage ../../pkgs/darwin-uninstaller { };

  mkToolModule = { name, package ? nix-tools.${name} }: { config, ... }: {
    options.system.tools.${name}.enable = lib.mkEnableOption "${name} script" // {
      default = ! config.system.disableInstallerTools;
      defaultText = "!config.system.disableInstallerTools";
    };

    config = lib.mkIf config.system.tools.${name}.enable {
      environment.systemPackages = [ package ];
    };
  };
in

{
  options.system = {
    disableInstallerTools = lib.mkOption {
      type = lib.types.bool;
      internal = true;
      default = false;
      description = ''
        Disable installer tools, such as darwin-rebuild and darwin-option. This
        is useful to shrink systems which are not expected to rebuild or
        reconfigure themselves. Use at your own risk!
    '';
    };
  };

  imports = [
    (lib.mkRenamedOptionModule [ "system" "includeUninstaller" ] [ "system" "tools" "darwin-uninstaller" "enable" ])

    (mkToolModule { name = "darwin-option"; })
    (mkToolModule { name = "darwin-rebuild"; })
    (mkToolModule { name = "darwin-version"; })
    (mkToolModule { name = "darwin-uninstaller"; package = darwin-uninstaller; })
  ];

  config = {
    system.build = {
      inherit (nix-tools) darwin-option darwin-rebuild darwin-version;
    };
  };
}
