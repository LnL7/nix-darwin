{ config, pkgs, ... }:

{
  programs.ssh.knownHosts = {
    "github.com" = {
      publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==";
    };
  };
  users.users.foo.openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAA..." ];

  test = ''
    echo >&2 "checking for github.com in /etc/ssh/ssh_known_hosts"
    grep 'github.com ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEAq2A7hRGmdnm9tUDbO9IDSwBK6TbQa+PXYPCPy6rbTrTtw7PHkccKrpp0yVhp5HdEIcKr6pLlVDBfOLX9QUsyCOV0wzfjIJNlGEYsdlLJizHhbn2mUjvSAHQqZETYP81eFzLQNnPHt4EVVUh7VfDESU84KezmD5QlWpXLmvU31/yMf+Se8xhHTvKSCZIFImWwoG6mbUoWf9nzpIoaSjB+weqqUUmpaaasXVal72J+UX2B+2RPW3RcT0eOzQgqlJL3RKrTJvdsjE3JEAvGq3lGHSZXy28G3skua2SmVi/w4yCE6gbODqnTWlg7+wC604ydGXA8VJiS5ap43JXiUFFAaQ==' ${config.out}/etc/ssh/ssh_known_hosts

    echo >&2 "checking for authorized keys for foo in /etc/ssh/nix_authorized_keys.d/foo"
    grep 'ssh-ed25519 AAAA...' ${config.out}/etc/ssh/nix_authorized_keys.d/foo
    echo >&2 "checking for authorized keys command in /etc/ssh/sshd_config.d/101-authorized-keys.conf"
    grep 'AuthorizedKeysCommand /bin/cat /etc/ssh/nix_authorized_keys.d/%u' ${config.out}/etc/ssh/sshd_config.d/101-authorized-keys.conf
  '';
}
