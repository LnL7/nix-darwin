{ config, pkgs, ... }:

{
  launchd.envVariables.FOO = "42";

  test = ''
    echo checking launchd setenv in /activate >&2
    grep "launchctl setenv FOO '42'" ${config.out}/activate
  '';
}
