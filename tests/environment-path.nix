{ config, lib, pkgs, ... }:

with lib;

{
  programs.bash.enable = true;

  test = ''
    echo checking /run/current-system/sw/bin in systemPath >&2
    grep 'export PATH=.*:/run/current-system/sw/bin' ${config.out}/etc/bashrc

    echo checking /bin and /sbin in systemPath >&2
    grep 'export PATH=.*:/usr/bin:/usr/sbin:/bin:/sbin' ${config.out}/etc/bashrc
  '';
}
