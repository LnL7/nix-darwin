{ config, lib, pkgs, ... }:
{
  environment.systemPackages =
    [ pkgs.lnl.tmux
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

  services.nix-daemon.enable = true;
  services.nix-daemon.tempDir = "/nix/tmp";

  services.activate-system.enable = true;

  system.defaults.NSGlobalDomain.AppleKeyboardUIMode = 3;
  system.defaults.NSGlobalDomain.ApplePressAndHoldEnabled = false;
  system.defaults.NSGlobalDomain.InitialKeyRepeat = 10;
  system.defaults.NSGlobalDomain.KeyRepeat = 1;
  system.defaults.NSGlobalDomain.NSAutomaticDashSubstitutionEnabled = false;
  system.defaults.NSGlobalDomain.NSAutomaticQuoteSubstitutionEnabled = false;
  system.defaults.NSGlobalDomain.NSAutomaticSpellingCorrectionEnabled = false;
  system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode = true;
  system.defaults.NSGlobalDomain.NSNavPanelExpandedStateForSaveMode2 = true;

  system.defaults.dock.autohide = true;
  system.defaults.dock.orientation = "left";
  system.defaults.dock.showhidden = true;
  system.defaults.dock.mru-spaces = false;

  system.defaults.finder.AppleShowAllExtensions = true;
  system.defaults.finder.QuitMenuItem = true;
  system.defaults.finder.FXEnableExtensionChangeWarning = false;

  system.defaults.trackpad.Clicking = true;

  programs.tmux.enable = true;
  programs.tmux.loginShell = "${config.programs.zsh.shell} -l";
  programs.tmux.enableSensible = true;
  programs.tmux.enableMouse = true;
  programs.tmux.enableFzf = true;
  programs.tmux.enableVim = true;

  programs.tmux.tmuxConfig = ''
    bind 0 set status

    set -g status-bg black
    set -g status-fg white
  '';

  programs.zsh.enable = true;

  programs.zsh.shellInit = ''
    export NIX_PATH=nixpkgs=$HOME/.nix-defexpr/nixpkgs:darwin=$HOME/.nix-defexpr/darwin:darwin-config=$HOME/.nixpkgs/darwin-config.nix:$HOME/.nix-defexpr/channels_root

    # Set up secure multi-user builds: non-root users build through the
    # Nix daemon.
    if [ "$USER" != root -a ! -w /nix/var/nix/db ]; then
        export NIX_REMOTE=daemon
    fi
  '';

  programs.zsh.loginShellInit = ''
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
        'i'|'instantiate')  nix-instantiate -E "with import <nixpkgs> {}; $@" ;;
        'r'|'repl')         nix-repl '<nixpkgs>' ;;
        's'|'shell')        nix-shell -E "with import <nixpkgs> {}; $@" ;;
        'p'|'package')      nix-shell '<nixpkgs>' -p "with import <nixpkgs> {}; $@" --run $SHELL ;;
        'z'|'zsh')          nix-shell '<nixpkgs>' -E "with import <nixpkgs> {}; $@" --run $SHELL ;;
        'exec')
          echo "reexecuting shell: $SHELL" >&2
          __ETC_ZSHRC_SOURCED= \
          __ETC_ZSHENV_SOURCED= \
          __ETC_ZPROFILE_SOURCED= \
            exec $SHELL -l
          ;;
      esac
    }

    cfg=$HOME/.nixpkgs/darwin-config.nix
    darwin=$HOME/.nix-defexpr/darwin
    pkgs=$HOME/.nix-defexpr/nixpkgs
  '';

  programs.zsh.interactiveShellInit = ''
    # history defaults
    SAVEHIST=2000
    HISTSIZE=2000
    HISTFILE=$HOME/.zsh_history

    setopt HIST_IGNORE_DUPS SHARE_HISTORY HIST_FCNTL_LOCK
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

  nixpkgs.config.allowUnfree = true;

  nixpkgs.config.packageOverrides = self: {
    lnl.tmux = pkgs.runCommand pkgs.tmux.name
      { buildInputs = [ pkgs.makeWrapper ]; }
      ''
        source $stdenv/setup

        mkdir -p $out/bin
        makeWrapper ${pkgs.tmux}/bin/tmux $out/bin/tmux \
          --set __ETC_ZPROFILE_SOURCED  "" \
          --set __ETC_ZSHENV_SOURCED "" \
          --set __ETC_ZSHRC_SOURCED "" \
          --add-flags -f --add-flags /etc/tmux.conf
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
      # vimrcConfig.vam.knownPlugins = with pkgs.vimUtils; (pkgs.vimPlugins // {
      #   vim-nix = buildVimPluginFrom2Nix {
      #     name = "vim-nix-unstable";
      #     src = ../../../vim-nix;
      #   };
      # });
      vimrcConfig.vam.pluginDictionaries = [
        { names = [ "fzfWrapper" "youcompleteme" "fugitive" "surround" "vim-nix" "colors-solarized" ]; }
      ];
    };
  };
}
