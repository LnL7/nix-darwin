{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ <user-darwin-config> ./installer.nix ];

  nix.configureBuildUsers = true;
  users.knownGroups = [ "nixbld" ];
}
