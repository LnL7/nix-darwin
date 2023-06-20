{ config, pkgs, ... }:

let
  nix-tools = pkgs.callPackage ../../pkgs/nix-tools {
    inherit (config.system) profile;
    inherit (config.environment) systemPath;
    nixPackage = config.nix.package;
  };

  inherit (nix-tools) darwin-option darwin-rebuild;
in

{
  config = {

    environment.systemPackages =
      [ # Include nix-tools by default
        darwin-option
        darwin-rebuild
      ];

    system.build = {
      inherit darwin-option darwin-rebuild;
    };

  };
}
