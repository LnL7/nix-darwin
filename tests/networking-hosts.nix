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

    grep '127.0.0.1' $file | head -n1 | grep localhost$ || exit 1
    grep '127.0.0.1' $file | tail -n1 | grep my.super.host$ || exit 2
    grep '::1' $file | grep localhost$ || exit 3
    grep '10.0.0.1' $file | grep my.super.host\ my.other.host$ || exit 4
  '';
}
