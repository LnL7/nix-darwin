{ config, lib, pkgs, ... }:

with lib;

{
  test = ''
    echo checking /usr/share/terminfo in environment >&2
    grep 'export TERMINFO=.*:/usr/share/terminfo' ${config.system.build.setEnvironment}
  '';
}
