{ config, pkgs, ... }:

let

  tools = pkgs.callPackage ../../pkgs/nix-tools {};

in

{
  config = {

    environment.systemPackages =
      [ # Include nix-tools by default
        tools.darwin-option
        tools.darwin-rebuild
      ];

  };
}
