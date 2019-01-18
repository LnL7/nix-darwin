{ config, pkgs, ... }:

{
   environment.systemPackages = [ pkgs.hello ];

   test = ''
     echo checking hello binary in /sw/bin >&2
     test "$(readlink -f ${config.out}/sw/bin/hello)" = "${pkgs.hello}/bin/hello"
   '';
}
