{ config, pkgs, ... }:

{
  users.knownGroups = [ "foo" "created.group" "deleted.group" ];
  users.groups.foo.gid = 42000;
  users.groups.foo.description = "Foo group";
  users.groups.foo.members = [ "admin" "foo" ];

  users.groups."created.group".gid = 42001;
  users.groups."unknown.group".gid = 42002;

  users.knownUsers = [ "foo" "created.user" "deleted.user" ];
  users.users.foo.uid = 42000;
  users.users.foo.gid = 42000;
  users.users.foo.description = "Foo user";
  users.users.foo.isHidden = true;
  users.users.foo.home = "/Users/foo";
  users.users.foo.shell = "/run/current-system/sw/bin/bash";

  users.users."created.user".uid = 42001;
  users.users."unknown.user".uid = 42002;

  test = ''
    echo "checking group creation in /activate" >&2
    grep "dscl . -create '/Groups/foo' PrimaryGroupID 42000" ${config.out}/activate
    grep "dscl . -create '/Groups/foo' RealName 'Foo group'" ${config.out}/activate
    grep "dscl . -create '/Groups/created.group' PrimaryGroupID 42001" ${config.out}/activate
    grep -qv "dscl . -delete '/Groups/created.group'" ${config.out}/activate

    echo "checking group deletion in /activate" >&2
    grep "dscl . -delete '/Groups/deleted.group'" ${config.out}/activate
    grep -qv "dscl . -create '/Groups/deleted.group'" ${config.out}/activate

    echo "checking group membership in /activate" >&2
    grep "dscl . -create '/Groups/foo' GroupMembership 'admin' 'foo'" ${config.out}/activate
    grep "dscl . -create '/Groups/created.group' GroupMembership" ${config.out}/activate

    echo "checking unknown group in /activate" >&2
    grep -qv "dscl . -create '/Groups/unknown.group'" ${config.out}/activate
    grep -qv "dscl . -delete '/Groups/unknown.group'" ${config.out}/activate

    echo "checking user creation in /activate" >&2
    grep "dscl . -create '/Users/foo' UniqueID 42000" ${config.out}/activate
    grep "dscl . -create '/Users/foo' PrimaryGroupID 42000" ${config.out}/activate
    grep "dscl . -create '/Users/foo' IsHidden 1" ${config.out}/activate
    grep "dscl . -create '/Users/foo' RealName 'Foo user'" ${config.out}/activate
    grep "dscl . -create '/Users/foo' NFSHomeDirectory '/Users/foo'" ${config.out}/activate
    grep "dscl . -create '/Users/foo' UserShell '/run/current-system/sw/bin/bash'" ${config.out}/activate
    grep "dscl . -create '/Users/created.user' UniqueID 42001" ${config.out}/activate
    grep -qv "dscl . -delete '/Groups/created.user'" ${config.out}/activate

    echo "checking user deletion in /activate" >&2
    grep "dscl . -delete '/Users/deleted.user'" ${config.out}/activate
    grep -qv "dscl . -create '/Users/deleted.user'" ${config.out}/activate

    echo "checking unknown user in /activate" >&2
    grep -qv "dscl . -create '/Users/unknown.user'" ${config.out}/activate
    grep -qv "dscl . -delete '/Users/unknown.user'" ${config.out}/activate
  '';
}
