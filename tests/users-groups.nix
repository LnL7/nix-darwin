{ config, pkgs, ... }:

{
  users.knownGroups = [ "foo" "bar" ];
  users.groups.foo.gid = 42000;
  users.groups.foo.description = "Foo group";

  users.groups.baz.gid = 43000;

  test = ''
    echo "checking group creation in /activate" >&2
    grep "dscl . -create '/Groups/foo' PrimaryGroupID 42000" ${config.out}/activate
    grep "dscl . -create '/Groups/foo' RealName 'Foo group'" ${config.out}/activate
    echo "checking group deletion in /activate" >&2
    grep "dscl . -delete '/Groups/bar'" ${config.out}/activate
    echo "checking unknown group in /activate" >&2
    grep -qv "dscl . -create '/Groups/bar'" ${config.out}/activate
    grep -qv "dscl . -delete '/Groups/bar'" ${config.out}/activate
  '';
}
