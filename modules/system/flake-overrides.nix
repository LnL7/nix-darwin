{ lib, inputs, ... }:

with lib;

let
  inherit (inputs) darwin nixpkgs;
in

{
  config = {
    system.checks.verifyNixPath = mkDefault false;

    system.darwinVersionSuffix = ".${darwin.shortRev or "dirty"}";
    system.darwinRevision = mkIf (darwin ? rev) darwin.rev;

    system.nixpkgsVersionSuffix = ".${substring 0 8 (nixpkgs.lastModifiedDate or nixpkgs.lastModified or "19700101")}.${nixpkgs.shortRev or "dirty"}";
    system.nixpkgsRevision = mkIf (nixpkgs ? rev) nixpkgs.rev;
  };
}
