{ config, lib, pkgs, ... }:

with lib;

{
  test = ''
    echo checking /run/current-system/sw/bin in environment >&2
    grep 'export PATH=.*:/run/current-system/sw/bin' ${config.system.build.setEnvironment}

    echo checking /bin and /sbin in environment >&2
    grep 'export PATH=.*:/usr/bin:/usr/sbin:/bin:/sbin' ${config.system.build.setEnvironment}
  '';
}
