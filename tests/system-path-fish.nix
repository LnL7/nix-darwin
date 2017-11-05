{ config, pkgs, ... }:

{
   environment.systemPath = [ pkgs.hello ];

   programs.fish.enable = true;

   test = ''
     echo checking systemPath in /etc/fish/config.fish >&2
     grep 'fenv export PATH=${pkgs.hello}/bin' ${config.out}/etc/fish/nixos-env-preinit.fish
   '';
}
