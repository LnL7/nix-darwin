{ ... }:

{
  system.activationScripts.createRun.text = ''
    IFS="." read -r -a macOSVersion <<< "$(sw_vers -productVersion)"

    if [[ ''${macOSVersion[0]} -gt 10 || ( ''${macOSVersion[0]} -eq 10 && ''${macOSVersion[1]} -ge 15 ) ]]; then
      if [[ $(stat -c '%a' /etc/synthetic.conf) != "644" ]]; then
        echo "fixing permissions on /etc/synthetic.conf..."
        sudo chmod 644 /etc/synthetic.conf
      fi

      if [[ $(grep -c '^run\b' /etc/synthetic.conf) -gt 1 ]]; then
        echo "found duplicate run entries in /etc/synthetic.conf, removing..."
        sudo sed -i "" -e '/^run\tprivate\/var\/run$/d' /etc/synthetic.conf
      fi

      if ! grep -q '^run\b' /etc/synthetic.conf 2>/dev/null; then
        echo "setting up /run via /etc/synthetic.conf..."
        printf 'run\tprivate/var/run\n' | sudo tee -a /etc/synthetic.conf >/dev/null
      fi

      if [[ ''${macOSVersion[0]} -gt 10 ]]; then
        sudo /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t || true
      else
        sudo /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -B || true
      fi

      if [[ ! -L /run ]]; then
        printf >&2 '[1;31merror: apfs.util failed to symlink /run, aborting activation[0m\n'
        printf >&2 'To create a symlink from /run to /var/run, please run:\n'
        printf >&2 '\n'
        printf >&2 "$ printf 'run\tprivate/var/run\n' | sudo tee -a /etc/synthetic.conf"

        if [[ ''${macOSVersion[0]} -gt 10 ]]; then
          printf >&2 '$ sudo /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t\n'
        else
          printf >&2 '$ sudo /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -B\n'
        fi

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
  '';
}
