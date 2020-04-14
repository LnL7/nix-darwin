{ config, pkgs, ... }:

{
   environment.shells = [ pkgs.zsh ];
   environment.currentSystemPath = /run/to/current/system;

   test = ''
     echo checking zsh in /etc/shells >&2
     grep '/run/to/current/system/sw/bin/zsh' ${config.out}/etc/shells
   '';
}
