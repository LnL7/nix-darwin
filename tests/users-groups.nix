{ lib, config, pkgs, ... }:

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
  users.users.foo.isHidden = false;
  users.users.foo.home = "/Users/foo";
  users.users.foo.createHome = true;
  users.users.foo.shell = pkgs.bashInteractive;

  users.users."created.user".uid = 42001;
  users.users."unknown.user".uid = 42002;

  test = ''
    set -v

    # checking group creation in /activate
    grep "dscl . -create '/Groups/foo' PrimaryGroupID 42000" ${config.out}/activate
    grep "dscl . -create '/Groups/foo' RealName 'Foo group'" ${config.out}/activate
    grep "dscl . -create '/Groups/created.group' PrimaryGroupID 42001" ${config.out}/activate
    grep -qv "dscl . -delete '/Groups/created.group'" ${config.out}/activate

    # checking group deletion in /activate
    grep "dscl . -delete '/Groups/deleted.group'" ${config.out}/activate
    grep -qv "dscl . -create '/Groups/deleted.group'" ${config.out}/activate

    echo "checking group membership in /activate" >&2
    grep "dscl . -create '/Groups/foo' GroupMembership 'admin' 'foo'" ${config.out}/activate
    grep "dscl . -create '/Groups/created.group' GroupMembership" ${config.out}/activate

    # checking unknown group in /activate
    grep -qv "dscl . -create '/Groups/unknown.group'" ${config.out}/activate
    grep -qv "dscl . -delete '/Groups/unknown.group'" ${config.out}/activate

    # checking user creation in /activate
    grep -zoP "sysadminctl -addUser 'foo' (.|\n)* -UID 42000 (.|\n)* -GID 42000 (.|\n)* -fullName 'Foo user' (.|\n)* -home '/Users/foo' (.|\n)* -shell ${lib.escapeShellArg "/run/current-system/sw/bin/bash"}" ${config.out}/activate
    grep "createhomedir -cu 'foo'" ${config.out}/activate
    grep -zoP "sysadminctl -addUser 'created.user' (.|\n)* -UID 42001 (.|\n)* -shell ${lib.escapeShellArg "/sbin/nologin"}" ${config.out}/activate
    grep -qv "sysadminctl -deleteUser ${lib.escapeShellArg "created.user"}" ${config.out}/activate
    grep -qv "sysadminctl -deleteUser ${lib.escapeShellArg "created.user"}" ${config.out}/activate

    # checking user properties always get updated in /activate
    grep "dscl . -create '/Users/foo' UserShell ${lib.escapeShellArg "/run/current-system/sw/bin/bash"}" ${config.out}/activate

    # checking user deletion in /activate
    grep "sysadminctl -deleteUser ${lib.escapeShellArg "deleted.user"}" ${config.out}/activate
    grep -qv "sysadminctl -addUser 'deleted.user'" ${config.out}/activate

    # checking unknown user in /activate
    grep -qv "sysadminctl -addUser 'unknown.user'" ${config.out}/activate
    grep -qv "sysadminctl -deleteUser ${lib.escapeShellArg "unknown.user"}" ${config.out}/activate

    set +v
  '';
}
