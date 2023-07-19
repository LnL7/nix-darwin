{ ... }:

{
  system.activationScripts.createRun.text = ''
    if ! test -L /run; then
      if ! grep -q '^run\b' /etc/synthetic.conf 2>/dev/null; then
          echo "setting up /run via /etc/synthetic.conf..."
          echo -e "run\tprivate/var/run" | sudo tee -a /etc/synthetic.conf >/dev/null
          sudo /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -B &>/dev/null || true
          sudo /System/Library/Filesystems/apfs.fs/Contents/Resources/apfs.util -t &>/dev/null || true
          if ! test -L /run; then
            echo "warning: apfs.util failed to symlink /run"
          fi
      fi
      if ! test -L /run; then
          echo "setting up /run..."
          sudo ln -sfn private/var/run /run
      fi
      if ! test -L /run; then
        echo "warning: failed to symlink /run"
      fi
    fi
  '';
}
