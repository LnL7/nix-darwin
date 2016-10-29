{ pkgs ? import <nixpkgs> {} }:

let

  eval = pkgs.lib.evalModules
    { check = true;
      args = { pkgs = import <nixpkgs> {}; };
      modules =
        [ config
          ./modules/system.nix
          ./modules/environment.nix
          ./modules/tmux.nix
          <nixpkgs/nixos/modules/system/etc/etc.nix>
        ];
    };

  config =
    { config, lib, pkgs, ... }:
    {
      environment.systemPackages =
        [ pkgs.lnl.vim
          pkgs.curl
          pkgs.fzf
          pkgs.gettext
          pkgs.git
          pkgs.jq
          pkgs.silver-searcher
          pkgs.tmux

          pkgs.nix-repl
          pkgs.nox
        ];

      environment.variables.EDITOR = "vim";
      environment.variables.HOMEBREW_CASK_OPTS = "--appdir=/Applications/cask";

      environment.variables.GIT_SSL_CAINFO = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";
      environment.variables.SSL_CERT_FILE = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";

      environment.etc."profile".text = ''
        source ${config.system.build.setEnvironment}
        source ${config.system.build.setAliases}

        conf=$HOME/src/nixpkgs-config
        pkgs=$HOME/.nix-defexpr/nixpkgs
      '';

      environment.shellAliases.l = "ls -lh";
      environment.shellAliases.ls = "ls -G";

      environment.etc."tmux.conf".text = ''
        source-file ${config.system.build.setTmuxOptions}

        bind 0 set status

        set -g status-bg black
        set -g status-fg white
      '';

      programs.tmux.enableSensible = true;
      programs.tmux.enableVim = true;

      environment.etc."zshrc".text = ''
        autoload -U compinit && compinit
        autoload -U promptinit && promptinit

        bindkey -e
        setopt autocd

        export PROMPT='%B%(?..[%?] )%b⇒ '
        export RPROMPT='%F{green}%~%f'

        export PATH=/var/run/current-system/sw/bin:/var/run/current-system/sw/bin''${PATH:+:$PATH}
        export PATH=/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin''${PATH:+:$PATH}
        export PATH=$HOME/.nix-profile/bin:$HOME/.nix-profile/bin''${PATH:+:$PATH}

        export NIX_PATH=nixpkgs=$HOME/.nix-defexpr/nixpkgs
        export NIX_REMOTE=daemon

        nixdarwin-rebuild () {
          case $1 in
            "build")  nix-build --no-out-link '<nixpkgs>' -A nixdarwin.toplevel ;;
            "repl")   nix-repl "$HOME/.nixpkgs/config.nix" ;;
            "shell")  nix-shell '<nixpkgs>' -p nixdarwin.toplevel --run "zsh -l" ;;
            "switch") nix-env -f '<nixpkgs>' -iA nixdarwin.toplevel && nix-shell '<nixpkgs>' -A nixdarwin.toplevel --run 'sudo $out/activate'  && exec zsh -l ;;
            "")       return 1 ;;
          esac
        }
      '';
    };


in {
  inherit eval;

  packageOverrides = self: {

    nixdarwin = eval.config.system.build;

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

        set clipboard=unnamed

        cmap <C-g> <Esc>
        imap <C-g> <Esc>
        nmap <C-g> <Esc>
        omap <C-g> <Esc>
        vmap <C-g> <Esc>

        set hlsearch
        nnoremap // :nohlsearch<cr>

        let mapleader = " "
        nnoremap <Leader>p :FZF<cr>
      '';
      vimrcConfig.vam.pluginDictionaries = [
        { names = [ "fzfWrapper" "youcompleteme" "fugitive" "surround" "vim-nix" "colors-solarized" ]; }
      ];
    };

  };
}
