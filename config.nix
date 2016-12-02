{ pkgs ? import <nixpkgs> {} }:

let

  eval = pkgs.lib.evalModules
    { check = true;
      args = { pkgs = import <nixpkgs> {}; };
      modules =
        [ config
          ./modules/system
          ./modules/system/activation-scripts.nix
          ./modules/system/defaults
          ./modules/system/etc.nix
          ./modules/system/launchd.nix
          ./modules/environment
          ./modules/launchd
          ./modules/programs/tmux.nix
        ];
    };

  config =
    { config, lib, pkgs, ... }:
    {
      environment.systemPackages =
        [ pkgs.lnl.zsh
          pkgs.lnl.tmux
          pkgs.lnl.vim
          pkgs.curl
          pkgs.fzf
          pkgs.gettext
          pkgs.git
          pkgs.jq
          pkgs.silver-searcher

          pkgs.nix-repl
          pkgs.nox
        ];

      launchd.daemons.nix-daemon =
        { serviceConfig.Program = "${pkgs.nix}/bin/nix-daemon";
          serviceConfig.KeepAlive = true;
          serviceConfig.RunAtLoad = true;
          serviceConfig.ProcessType = "Background";
          serviceConfig.SoftResourceLimits.NumberOfFiles = 4096;
          serviceConfig.EnvironmentVariables.NIX_BUILD_HOOK="/nix/var/nix/profiles/default/libexec/nix/build-remote.pl";
          serviceConfig.EnvironmentVariables.NIX_CURRENT_LOAD="/nix/tmp/current-load";
          serviceConfig.EnvironmentVariables.NIX_REMOTE_SYSTEMS="/etc/nix/machines";
          serviceConfig.EnvironmentVariables.SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
          serviceConfig.EnvironmentVariables.TMPDIR = "/nix/tmp";
        };

      system.defaults.global.InitialKeyRepeat = 10;
      system.defaults.global.KeyRepeat = 1;

      programs.tmux.loginShell = "${pkgs.lnl.zsh}/bin/zsh -l";
      programs.tmux.enableSensible = true;
      programs.tmux.enableMouse = true;
      programs.tmux.enableFzf = true;
      programs.tmux.enableVim = true;

      programs.tmux.tmuxConfig = ''
        bind 0 set status

        set -g status-bg black
        set -g status-fg white
      '';

      environment.variables.EDITOR = "vim";
      environment.variables.HOMEBREW_CASK_OPTS = "--appdir=/Applications/cask";

      environment.variables.GIT_SSL_CAINFO = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      environment.variables.SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

      environment.shellAliases.l = "ls -lh";
      environment.shellAliases.ls = "ls -G";
      environment.shellAliases.g = "git log  --oneline --max-count 42";
      environment.shellAliases.gl = "git log --graph --oneline";
      environment.shellAliases.gd = "git diff --minimal --patch";

      environment.etc."zprofile".text = ''
        # /etc/zprofile: DO NOT EDIT -- this file has been generated automatically.
        # This file is read for login shells.

        # Only execute this file once per shell.
        if [ -n "$__ETC_ZPROFILE_SOURCED" ]; then return; fi
        __ETC_ZPROFILE_SOURCED=1

        autoload -U promptinit && promptinit
        PROMPT='%B%(?..%? )%b⇒ '
        RPROMPT='%F{green}%~%f'

        bindkey -e
        setopt autocd

        autoload -U compinit && compinit

        nix () {
          cmd=$1
          shift

          case $cmd in
            'b'|'build')        nix-build --no-out-link -E "with import <nixpkgs> {}; $@" ;;
            'e'|'eval')         nix-instantiate --eval -E "with import  <nixpkgs> {}; $@" ;;
            'i'|'instantiate')  nix-instantiate -E "with import  <nixpkgs> {}; $@" ;;
            'r'|'repl')         nix-repl '<nixpkgs>' ;;
            's'|'shell')        nix-shell -E "with import <nixpkgs> {}; $@" ;;
            'x'|'exec')         nix-shell '<nixpkgs>' -p "$@" --run zsh ;;
            'z'|'zsh')          nix-shell '<nixpkgs>' -A "$@" --run zsh ;;
          esac
        }

        nixdarwin-rebuild () {
          cmd=$1
          shift

          case $cmd in
            'build')   nix-build --no-out-link '<nixpkgs>' -A nixdarwin.toplevel "$@" ;;
            'repl')    nix-repl "$HOME/.nixpkgs/config.nix" "$@" ;;
            'shell')   nix-shell '<nixpkgs>' -p nixdarwin.toplevel --run '${pkgs.lnl.zsh}/bin/zsh -l' "$@" ;;
            'switch')  sudo nix-env --profile /nix/var/nix/profiles/system --set $(nix-build --no-out-link '<nixpkgs>' -A nixdarwin.toplevel) && nix-shell '<nixpkgs>' -A nixdarwin.toplevel --run 'sudo $out/activate' && exec ${pkgs.lnl.zsh}/bin/zsh -l ;;
          esac
        }

        conf=$HOME/src/nixpkgs-config
        pkgs=$HOME/.nix-defexpr/nixpkgs

        # Read system-wide modifications.
        if test -f /etc/zprofile.local; then
          . /etc/zprofile.local
        fi
      '';

      environment.etc."zshenv".text = ''
        # /etc/zshenv: DO NOT EDIT -- this file has been generated automatically.
        # This file is read for all shells.

        # Only execute this file once per shell.
        # But don't clobber the environment of interactive non-login children!

        if [ -n "$__ETC_ZSHENV_SOURCED" ]; then return; fi
        export __ETC_ZSHENV_SOURCED=1

        export NIX_PATH=nixpkgs=$HOME/.nix-defexpr/nixpkgs:$NIX_PATH/.nix-defexpr/channels_root

        # Set up secure multi-user builds: non-root users build through the
        # Nix daemon.
        if [ "$USER" != root -a ! -w /nix/var/nix/db ]; then
            export NIX_REMOTE=daemon
        fi

        # Read system-wide modifications.
        if test -f /etc/zshenv.local; then
          . /etc/zshenv.local
        fi
      '';

      environment.etc."zshrc".text = ''
        # /etc/zshrc: DO NOT EDIT -- this file has been generated automatically.
        # This file is read for interactive shells.

        # Only execute this file once per shell.
        if [ -n "$__ETC_ZSHRC_SOURCED" -o -n "$NOSYSZSHRC" ]; then return; fi
        __ETC_ZSHRC_SOURCED=1

        # history defaults
        SAVEHIST=2000
        HISTSIZE=2000
        HISTFILE=$HOME/.zsh_history

        setopt HIST_IGNORE_DUPS SHARE_HISTORY HIST_FCNTL_LOCK

        export PATH=${config.environment.systemPath}''${PATH:+:$PATH}
        typeset -U PATH

        ${config.system.build.setEnvironment}
        ${config.system.build.setAliases}

        # Read system-wide modifications.
        if test -f /etc/zshrc.local; then
          . /etc/zshrc.local
        fi
      '';
    };


in {
  inherit eval;

  allowUnfree = true;

  packageOverrides = self: {

    nixdarwin = eval.config.system.build;

    lnl.zsh = pkgs.runCommand pkgs.zsh.name
      { buildInputs = [ pkgs.makeWrapper ]; }
      ''
        source $stdenv/setup

        mkdir -p $out/bin
        makeWrapper "${pkgs.zsh}/bin/zsh" "$out/bin/zsh"
      '';

    lnl.tmux = pkgs.runCommand pkgs.tmux.name
      { buildInputs = [ pkgs.makeWrapper ]; }
      ''
        source $stdenv/setup

        mkdir -p $out/bin
        makeWrapper "${pkgs.tmux}/bin/tmux" "$out/bin/tmux" \
          --add-flags -f --add-flags "/run/current-system/etc/tmux.conf" \
      '';

    lnl.vim = pkgs.vim_configurable.customize {
      name = "vim";
      vimrcConfig.customRC = ''
        set nocompatible
        filetype plugin indent on
        syntax on

        colorscheme solarized
        set bg=dark

        set et sw=2 ts=2
        set bs=indent,start

        set nowrap
        set list
        set listchars=tab:»·,trail:·,extends:⟩,precedes:⟨
        set fillchars+=vert:\ ,stl:\ ,stlnc:\ 

        set lazyredraw

        set clipboard=unnamed

        vmap s S

        cnoremap %% <C-r>=expand('%:h') . '/'<CR>

        set hlsearch
        nnoremap // :nohlsearch<CR>

        let mapleader = ' '
        nnoremap <Leader>p :FZF<CR>
        nnoremap <silent> <Leader>e :exe 'FZF ' . expand('%:h')<CR>

        source $HOME/.vimrc.local
      '';
      vimrcConfig.vam.knownPlugins = with pkgs.vimUtils; (pkgs.vimPlugins // {
        vim-nix = buildVimPluginFrom2Nix {
          name = "vim-nix-unstable";
          src = ../vim-nix;
        };
      });
      vimrcConfig.vam.pluginDictionaries = [
        { names = [ "fzfWrapper" "youcompleteme" "fugitive" "surround" "vim-nix" "colors-solarized" ]; }
      ];
    };

  };
}
