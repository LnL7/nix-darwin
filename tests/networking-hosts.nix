{ config, pkgs, ... }:

{
  networking.hosts = {
    "127.0.0.1" = [ "my.super.host" ];
    "10.0.0.1" = [ "my.super.host" "my.other.host" ];
  };

  test = ''
    echo checking /etc/hosts file >&2

    file=${config.out}/etc/hosts
    grep '127.0.0.1' $file
    grep '10.0.0.1 my.super.host my.other.host' $file
  '';
}
