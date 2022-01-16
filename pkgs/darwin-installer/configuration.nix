{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ <user-darwin-config> ./installer.nix ];

  users.nix.configureBuildUsers = true;
  users.knownGroups = [ "nixbld" ];
}
