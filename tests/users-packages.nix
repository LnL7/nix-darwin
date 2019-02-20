{ config, pkgs, ... }:

{
  users.knownUsers = [ "foo" ];
  users.users.foo.uid = 42000;
  users.users.foo.gid = 42000;
  users.users.foo.description = "Foo user";
  users.users.foo.isHidden = false;
  users.users.foo.home = "/Users/foo";
  users.users.foo.shell = "/run/current-system/sw/bin/bash";
  users.users.foo.packages = [ pkgs.hello ];

  test = ''
    echo "checking for hello in /etc/profiles/per-user/foo" >&2
    test -x /etc/profiles/per-user/foo/bin/hello
  '';
}
