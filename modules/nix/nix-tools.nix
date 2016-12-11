{ config, pkgs, ... }:

let

  tools = pkgs.callPackage ../../pkgs/nix-tools {};

in

{
  config = {

    system.build.nix = pkgs.runCommand "nix-darwin" {} ''
      mkdir -p $out/bin
      ln -s ${tools.darwin-option} $out/bin/darwin-option
      ln -s ${tools.darwin-rebuild} $out/bin/darwin-rebuild
    '';

  };
}
