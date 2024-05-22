{ config, lib, pkgs, ... }:

with lib;

{
  test = ''
    echo 'checking PATH' >&2
    env_path=$(bash -c 'source ${config.system.build.setEnvironment}; echo $PATH')

    test "$env_path" = "${builtins.concatStringsSep ":" [
      "/homeless-shelter/.nix-profile/bin"
      "/run/current-system/sw/bin"
      "/nix/var/nix/profiles/default/bin"
      "/usr/local/bin"
      "/usr/bin"
      "/usr/sbin"
      "/bin"
      "/sbin"
    ]}"
  '';
}
