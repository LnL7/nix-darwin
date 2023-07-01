{ config, pkgs, ... }:

let
  nix-tools = pkgs.callPackage ../../pkgs/nix-tools {
    inherit (config.system) profile;
    inherit (config.environment) systemPath;
    nixPackage = config.nix.package;
  };

  inherit (nix-tools) darwin-option darwin-rebuild darwin-version;
in

{
  config = {

    environment.systemPackages =
      [ # Include nix-tools by default
        darwin-option
        darwin-rebuild
        darwin-version
      ];

    system.build = {
      inherit darwin-option darwin-rebuild darwin-version;
    };

  };
}
