{ config, pkgs, ... }:

{
  networking.hosts = {
    "127.0.0.1" = [ "my.super.host" ];
    "10.0.0.1" = [ "my.super.host" "my.other.host" ];
  };

  test = ''
    echo checking /etc/hosts file >&2

    file=${config.out}/etc/hosts

    if [[ ! $(grep '127.0.0.1' $file | head -n1) =~ localhost$ ]]; then
      cat $file
      echo "'$(grep '127.0.0.1' $file | head -n1)'"
      exit 1
    fi
    if [[ ! $(grep '127.0.0.1' $file | tail -n1) =~ my.super.host$ ]]; then
      cat $file
      echo "'$(grep '127.0.0.1' $file | tail -n1)'"
      exit 2
    fi
    if [[ ! $(grep '::1' $file) =~ localhost$ ]]; then
      cat $file
      echo "'$(grep '::1' $file)'"
      exit 3
    fi
    if [[ ! $(grep '10.0.0.1' $file) =~ my.super.host\ my.other.host$ ]]; then
      cat $file
      echo "'$(grep '10.0.0.1' $file)'"
      exit 4
    fi
  '';
}
