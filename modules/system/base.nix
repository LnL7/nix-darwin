{ ... }:

{
  system.activationScripts.createRun.text = ''
    if [[ ! -L /run ]]; then
      # This file doesn't exist by default on macOS and is only supported after 10.15
      # however every system with Nix installed should have this file otherwise `/nix`
      # wouldn't exist.
      if [[ -e /etc/synthetic.conf ]]; then
        if ! grep -q '^run\b' /etc/synthetic.conf 2>/dev/null; then
          echo "setting up /run via /etc/synthetic.conf..."
          printf 'run\tprivate/var/run\n' | sudo tee -a /etc/synthetic.conf >/dev/null
        fi

        # for Catalina (10.15)
        sudo /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -B &>/dev/null || true
        # for Big Sur (11.0)
        sudo /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t &>/dev/null || true

        if [[ ! -L /run ]]; then
          printf >&2 '[1;31merror: apfs.util failed to symlink /run, aborting activation[0m\n'
          printf >&2 'To create a symlink from /run to /var/run, please run:\n'
          printf >&2 '\n'
          printf >&2 "$ printf 'run\tprivate/var/run\n' | sudo tee -a /etc/synthetic.conf"
          printf >&2 '$ sudo /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -B # For Catalina\n'
          printf >&2 '$ sudo /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t # For Big Sur and later\n' >&2
          printf >&2 '\n'
          printf >&2 'The current contents of /etc/synthetic.conf is:\n'
          printf >&2 '\n'
          sudo sed 's/^/    /' /etc/synthetic.conf >&2
          printf >&2 '\n'
          exit 1
        fi
      else
        echo "setting up /run..."
        sudo ln -sfn private/var/run /run

        if [[ ! -L /run ]]; then
          printf >&2 '[1;31merror: failed to symlink /run, aborting activation[0m\n'
          printf >&2 'To create a symlink from /run to /var/run, please run:\n'
          printf >&2 '\n'
          printf >&2 '$ sudo ln -sfn private/var/link /run\n'
          exit 1
        fi
      fi
    fi
  '';
}
