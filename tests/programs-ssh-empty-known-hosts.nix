{ config, pkgs, ... }:

{
  test = ''
    echo >&2 "checking existance of /etc/ssh/ssh_known_hosts"
    if test -e ${config.out}/etc/ssh/ssh_known_hosts; then
      echo >&2 "/etc/ssh/ssh_known_hosts exists but it shouldn't!"
      exit 1
    fi
  '';
}
