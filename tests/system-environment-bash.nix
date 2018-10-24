{ config, pkgs, ... }:

{
   programs.bash.enable = true;

   test = ''
     echo checking setEnvironment in /etc/bashrc >&2
     fgrep '. ${config.system.build.setEnvironment}' ${config.out}/etc/bashrc
   '';
}
