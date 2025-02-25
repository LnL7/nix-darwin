{ config, pkgs, ... }:

{
  networking.hosts = {
    "127.0.0.1" = [ "my.super.host" ];
    "10.0.0.1" = [ "my.super.host" "my.other.host" ];
  };

  test = ''
    set -v
    echo checking /etc/hosts file >&2

    file=${config.out}/etc/hosts

    grep '127.0.0.1' $file | head -n1 | grep localhost$
    grep '127.0.0.1' $file | tail -n1 | grep my.super.host$
    grep '::1' $file | grep localhost$
    grep '10.0.0.1' $file | grep my.super.host\ my.other.host$
  '';
}
