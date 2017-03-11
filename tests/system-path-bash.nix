{ config, pkgs, ... }:

{
   environment.systemPath = [ pkgs.hello ];

   programs.bash.enable = true;

   test = ''
     echo checking systemPath in /etc/bashrc >&2
     grep 'export PATH=${pkgs.hello}/bin' ${config.out}/etc/bashrc
   '';
}
