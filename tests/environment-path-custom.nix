{ config, lib, pkgs, ... }:

with lib;

{
  environment.currentSystemPath = /run/to/current/system;

  test = ''
    echo checking /run/to/current/system/sw/bin in environment >&2
    grep 'export PATH=.*:/run/to/current/system/sw/bin' ${config.system.build.setEnvironment}
  '';
}
