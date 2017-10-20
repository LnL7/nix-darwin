{ config, lib, pkgs, ... }:

with lib;

let
  nix-info = pkgs.nix-info or null;
in

{
  config = {

    environment.systemPackages = mkIf (nix-info != null) [ nix-info ];

  };
}
