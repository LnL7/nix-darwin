{ config, pkgs, ... }:

{
  networking.hosts = {
    "127.0.0.1" = [ "my.super.host" ];
    "10.0.0.1" = [ "my.super.host" "my.other.host" ];
  };

  test = ''
    echo checking /etc/hosts file >&2

    file=${config.out}/etc/hosts

    if ! grep '127.0.0.1' $file | head -n1 | grep localhost$; then
      exit 1
    fi
    if ! grep '127.0.0.1' $file | tail -n1 | grep my.super.host$; then
      exit 2
    fi
    if ! grep '::1' $file | grep localhost$; then
      exit 3
    fi
    if ! grep '10.0.0.1' $file | grep my.super.host\ my.other.host$; then
      exit 4
    fi
  '';
}
