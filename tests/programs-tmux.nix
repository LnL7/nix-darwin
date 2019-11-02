{ config, pkgs, ... }:

{
  programs.tmux.enable = true;
  programs.tmux.enableVim = true;

  test = ''
    echo "checking for tmux in /sw/bin" >&2
    test -x ${config.out}/sw/bin/tmux
    grep "__ETC_ZSHRC_SOURCED=${"''"}" ${config.out}/sw/bin/tmux
    grep "__NIX_DARWIN_SET_ENVIRONMENT_DONE=${"''"}" ${config.out}/sw/bin/tmux

    echo "checking for tmux.conf in /etc" >&2
    test -e ${config.out}/etc/tmux.conf
    grep "setw -g mode-keys vi" ${config.out}/etc/tmux.conf
  '';
}
