{ config, pkgs, ... }:

{
   environment.systemPath = [ pkgs.hello ];

   programs.zsh.enable = true;

   test = ''
     echo checking systemPath in /etc/zshrc >&2
     grep 'export PATH=${pkgs.hello}/bin' ${config.out}/etc/zshrc
   '';
}
