{ config, pkgs, ... }:

{
   programs.fish.enable = true;

   test = ''
     echo checking setEnvironment in /etc/fish/config.fish >&2
     grep 'fenv source ${config.system.build.setEnvironment}' ${config.out}/etc/fish/nixos-env-preinit.fish
   '';
}
